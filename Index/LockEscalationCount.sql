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
