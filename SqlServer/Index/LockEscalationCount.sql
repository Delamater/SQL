/*
This example will: 
1. Create a new table
2. Inject records
3. Index the table
4. SELECT with a update lock simulating the intent to hold the row in a lock for a future update
5. The user running this script will then need to open a new spid and delete the records to create contention
6. Finally, back to this spid, run the sql query to identify lock escalations
*/


SET NOCOUNT ON
IF OBJECT_ID('dbo.tmpLockExample','u') IS NOT NULL
BEGIN 
	PRINT 'Dropping dbo.tmpLockExample'
	DROP TABLE dbo.tmpLockExample
END
CREATE TABLE dbo.tmpLockExample(ID INT IDENTITY(1,1), FNAME NVARCHAR(50) NULL, LNAME NVARCHAR(MAX));
GO
INSERT INTO dbo.tmpLockExample(FNAME,LNAME) SELECT CAST(NEWID() AS NVARCHAR(50)), space(10000)
GO 10000

CREATE CLUSTERED INDEX clsID ON dbo.tmpLockExample(ID)
CREATE NONCLUSTERED INDEX xCovering ON dbo.tmpLockExample(ID) INCLUDE(FNAME,LNAME)

-- Check to see the number of pages 
SELECT 
	DB_NAME(database_id) DatabaseName, 
	OBJECT_SCHEMA_NAME(object_id) SchemaName,
	index_type_desc, 
	index_depth, 
	index_level, 
	page_count,
	record_count
FROM sys.dm_db_index_physical_stats(db_id(), object_id('dbo.tmpLockExample'),null,null,'DETAILED')

BEGIN TRAN
SELECT *, DATALENGTH(LNAME)
FROM dbo.tmpLockExample --WITH(UPDLOCK, ROWLOCK)
WHERE ID BETWEEN 000 AND 10000 


PRINT 'Open a second connection here and run BEGIN TRAN DELETE dbo.tmp'
PRINT 'Next, come back to this spid and run the query below while the second query is waiting'
WAITFOR DELAY '00:00:30' -- Wait 30 seconds
WAITFOR DELAY '00:00:02';

/*
https://www.simple-talk.com/sql/performance/tune-your-indexing-strategy-with-sql-server-dmvs/
Identify lock escalations

SQL Server may attempt to escalate locks in response to a need to reduce the total 
number of locks being held and the memory therefore required to hold and manage them. 
For example, individual row locks may be escalated to a single table lock, or page 
locks may be escalated to a table lock. While this will result in lower overhead 
on SQL Server, the downside is lower concurrency. If processes are running on your 
servers that are causing lock escalation, it’s worth investigating whether the escalation 
is justified, or if SQL tuning can be performed to prevent it.

The sys.dm_db_index_operational_stats DMV can be queried to return information on the count 
of attempts made by SQL Server to escalate row and page locks to table locks for a 
specific object. The query in Listing 9 provides information regarding how frequently these 
escalation attempts were made, and the percentage success in performing the escalation.
*/
SELECT  OBJECT_NAME(ddios.[object_id], ddios.database_id) AS [object_name] ,
        i.name AS index_name ,
        ddios.index_id ,
        ddios.partition_number ,
        ddios.index_lock_promotion_attempt_count ,
        ddios.index_lock_promotion_count ,
        ( ddios.index_lock_promotion_attempt_count
          / ddios.index_lock_promotion_count ) AS percent_success
FROM    sys.dm_db_index_operational_stats(DB_ID(), NULL, NULL, NULL) ddios
        INNER JOIN sys.indexes i ON ddios.OBJECT_ID = i.OBJECT_ID
                                    AND ddios.index_id = i.index_id
WHERE   ddios.index_lock_promotion_count > 0 

COMMIT
