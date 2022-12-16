/*Listing 2-1: Creating a database.*/
USE master
GO
IF EXISTS (SELECT * FROM sys.databases WHERE name='HKDB')
      DROP DATABASE HKDB;
GO
  CREATE DATABASE HKDB
    ON 
    PRIMARY(NAME = [HKDB_data], 
         FILENAME = 'Q:\DataHK\HKDB_data.mdf', size=500MB), 
    FILEGROUP [HKDB_mod_fg] CONTAINS MEMORY_OPTIMIZED_DATA
         (NAME = [HKDB_mod_dir], 
          FILENAME = 'R:\DataHK\HKDB_mod_dir'),
         (NAME = [HKDB_mod_dir], 
          FILENAME = 'S:\DataHK\HKDB_mod_dir') 

   LOG ON (name = [HKDB_log],
           Filename='L:\LogHK\HKDB_log.ldf', size=500MB)
   COLLATE Latin1_General_100_BIN2;
GO


/*Listing 2-2: Adding a filegroup and file for storing memory-optimized table data.*/
ALTER DATABASE MyAW2012 
      ADD FILEGROUP MyAW2012_mod_fg CONTAINS MEMORY_OPTIMIZED_DATA;
GO
ALTER DATABASE MyAW2012 
      ADD FILE (NAME='MyAW012_mod_dir',
                  FILENAME='c:\DataHK\MyAW2012_mod_dir') 
       TO FILEGROUP MyAW2012_mod_fg;
GO

/*Listing 2-3: Creating a memory-optimized table with the index definition inline.*/
USE HKDB;
GO
CREATE TABLE T1
(
   [Name] varchar(32) not null PRIMARY KEY NONCLUSTERED HASH WITH (BUCKET_COUNT = 100000),
   [City] varchar(32) null,
   [State_Province] varchar(32) null,
   [LastModified] datetime not null,

) WITH (MEMORY_OPTIMIZED = ON, DURABILITY = SCHEMA_AND_DATA);
GO


/*Listing 2-4: Creating an in-memory table with 2 indexes defined inline.*/
CREATE TABLE T1
(
   [Name] varchar(32) not null PRIMARY KEY NONCLUSTERED WITH (BUCKET_COUNT = 100000),
   [City] varchar(32) not null INDEX T1_hdx_c2 HASH
                                WITH (BUCKET_COUNT = 10000),
   [State_Province] varchar(32) null,
   [LastModified] datetime not null,
	
) WITH (MEMORY_OPTIMIZED = ON, DURABILITY = SCHEMA_AND_DATA);
GO


/*Listing 2-5: Creating a memory-optimized table with the index definition specified separately.*/
CREATE TABLE T2
(
   [Name] varchar(32) not null PRIMARY KEY NONCLUSTERED HASH WITH (BUCKET_COUNT = 100000),
   [City] varchar(32) not null,
   [State_Province] varchar(32) not null,
   [LastModified] datetime not null,

  INDEX T1_ndx_c2c3 NONCLUSTERED ([City],[State_Province]) 

) WITH (MEMORY_OPTIMIZED = ON, DURABILITY = SCHEMA_AND_DATA);
GO


/*Listing 2-6: Querying tables in a database that uses a BIN2 collation.*/
USE HKDB;
GO
-- This statement will generate an error, 
-- due to the case sensitivity of object names (note the lower case t)
SELECT  *
FROM    t1; 
GO

-- This statement will succeed
SELECT  *
FROM    T1;
GO

-- Now insert three rows into the table
INSERT  INTO T1
VALUES  ( 'da Vinci', 'Vinci', 'FL', GETDATE() );
INSERT  INTO T1
VALUES  ( 'Botticelli', 'Florence', 'FL', GETDATE() );
INSERT  INTO T1
VALUES  ( 'Donatello', 'Florence', 'FL', GETDATE() );
GO

-- returns an empty result due to uppercase 'D'
SELECT  *
FROM    T1
WHERE   Name = 'Da Vinci';
GO

-- generates 'invalid column name' error on name
SELECT  *
FROM    T1
WHERE   name = 'da Vinci';
GO

-- returns 1 row
SELECT  *
FROM    T1
WHERE   Name = 'da Vinci'; 
GO

-- "da Vinci" appears last in the ordering because, with a BIN2 collation,
-- any upper-case characters sort before all lower-case characters
SELECT  *
FROM    T1
ORDER BY Name;

-- We can set the collation in the query, to match instance collation.
-- However, as with all conversions, SARGability will be an issue

-- returns "expected" results, but SQL Server will perform a table scan
SELECT  *
FROM    T1
WHERE   Name = 'Da Vinci' COLLATE Latin1_General_CI_AS; 
GO
-- returns "expected" order but, as above, an index cannot be used to support
-- the ordering
SELECT  *
FROM    T1
ORDER BY Name COLLATE Latin1_General_CI_AS;
GO


/*Listing 2-7: Specifying collations at the column level, during table creation.*/
USE HKDB;
GO
CREATE TABLE T1
(
   [Name] varchar(32) COLLATE Latin1_General_100_BIN2 not null
                                   PRIMARY KEY NONCLUSTERED HASH WITH (BUCKET_COUNT = 100000),
   [City] varchar(32) COLLATE Latin1_General_100_BIN2 null,
   [State_Province]  varchar(32) COLLATE Latin1_General_100_BIN2 null,
   [LastModified] datetime not null,

) WITH (MEMORY_OPTIMIZED = ON, DURABILITY = SCHEMA_AND_DATA);
GO


/*Listing 4-1: Defining a hash index.*/
CREATE TABLE T1
(
   [Name] varchar(32) not null PRIMARY KEY NONCLUSTERED HASH WITH (BUCKET_COUNT = 100000),
   [City] varchar(32) null,
   [State_Province] varchar(32) null,
   [LastModified] datetime not null,
	
) WITH (MEMORY_OPTIMIZED = ON, DURABILITY = SCHEMA_AND_DATA);
GO


/*Listing 5-1: Recreate memory-optimized table, T1.*/
USE HKDB
GO
IF EXISTS (SELECT * FROM sys.objects WHERE name='T1')
      DROP TABLE [dbo].[T1]
GO

CREATE TABLE T1
(
   [Name] varchar(32) not null PRIMARY KEY NONCLUSTERED HASH WITH (BUCKET_COUNT = 100000),
   [City] varchar(32) null,
   [State_Province] varchar(32) null,
   [LastModified] datetime not null,

) WITH (MEMORY_OPTIMIZED = ON, DURABILITY = SCHEMA_AND_DATA);
GO

/*Listing 5-2: Explicit transaction against T1.*/
USE HKDB;
BEGIN TRAN;
SELECT  *
FROM    [dbo].[T1]
COMMIT TRAN;
GO

/*Listing 5-3: Explicit transaction using a table hint to specify snapshot isolation.*/
USE HKDB;
BEGIN TRAN;
SELECT  * FROM [dbo].[T1] WITH (SNAPSHOT);
COMMIT TRAN;
GO

/*Listing 5-4: READ COMMITTED isolation is supported only for auto-commit transactions.*/
INSERT  [dbo].[T1]
        ( Name, City, LastModified )
VALUES  ( 'Jane', 'Helsinki', CURRENT_TIMESTAMP ),
        ( 'Susan', 'Vienna', CURRENT_TIMESTAMP ),
        ( 'Greg', 'Lisbon', CURRENT_TIMESTAMP );
GO

/*Listing 5-5: Attempting to access a memory-optimized table using SNAPSHOT isolation.*/
ALTER DATABASE HKDB
SET ALLOW_SNAPSHOT_ISOLATION ON;

SET TRANSACTION ISOLATION LEVEL SNAPSHOT
USE HKDB;
BEGIN TRAN;
SELECT  *
FROM    [dbo].[T1] WITH ( REPEATABLEREAD );
COMMIT TRAN;

SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

ALTER DATABASE HKDB
SET ALLOW_SNAPSHOT_ISOLATION OFF;
GO

/*Listing 5-6: Attempting to access a memory-optimized table using REPEATABLE READ isolation.*/
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
USE HKDB;
BEGIN TRAN;
SELECT  *
FROM    [dbo].[T1];
COMMIT TRAN;
GO

/*Listing 5-7: A REPEATABLE READ transaction accessing a T1 using snapshot isolation.*/
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
USE HKDB;
BEGIN TRAN;
SELECT  *
FROM    [dbo].[T1]WITH ( SNAPSHOT );
COMMIT TRAN;

SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
GO

/*Listing 5-8: Setting the database option to elevate isolation level to SNAPSHOT.*/
ALTER DATABASE HKDB
SET MEMORY_OPTIMIZED_ELEVATE_TO_SNAPSHOT ON;
GO

/*Listing 5-9: Verifying if the database has been set to elevate the isolation level to SNAPSHOT.*/
SELECT  is_memory_optimized_elevate_to_snapshot_on
FROM    sys.databases
WHERE   name = 'HKDB';

SELECT  DATABASEPROPERTYEX('HKDB',
                           'IsMemoryOptimizedElevateToSnapshotEnabled');
GO

/*Listing 5-10: Monitoring transactions on memory-optimized tables.*/
SELECT  xtp_transaction_id ,
        transaction_id ,
        session_id ,
        begin_tsn ,
        end_tsn ,
        state_desc
FROM    sys.dm_db_xtp_transactions
WHERE   transaction_id > 0;
GO

/*Listing 5-11: Tx1 deletes one row and updates another.*/
USE HKDB;
BEGIN TRAN Tx1;
DELETE  FROM dbo.T1 WITH ( SNAPSHOT )
WHERE   Name = 'Greg';
UPDATE  dbo.T1 WITH ( SNAPSHOT )
SET     City = 'Perth'
WHERE   Name = 'Jane';
-- COMMIT TRAN Tx1
GO

/*Listing 5-12: TxU attempts to update a row while Tx1 is still uncommitted.*/
USE HKDB;
BEGIN TRAN TxU;
UPDATE  dbo.T1 WITH ( SNAPSHOT )
SET     City = 'Melbourne'
WHERE   Name = 'Jane';
COMMIT TRAN TxU
GO

/*Listing 5-13: Tx2 runs a single-statement SELECT.*/
USE HKDB;
SELECT  Name ,
        City
FROM    T1;
GO

/*Listing 5-14: Tx3 reads the value of City for "Jane" and updates the "Susan" row with this value.*/
DECLARE @City NVARCHAR(32);
BEGIN TRAN TX3
SELECT  @City = City
FROM    T1 WITH ( REPEATABLEREAD )
WHERE   Name = 'Jane';
UPDATE  T1 WITH ( REPEATABLEREAD )
SET     City = @City
WHERE   Name = 'Susan';
COMMIT TRAN  -- commits at time-stamp 260
GO

/*Listing 5-15: Observing the process of garbage collection.*/
SELECT  name AS 'index_name' ,
        s.index_id ,
        scans_started ,
        rows_returned ,
        rows_expired ,
        rows_expired_removed
FROM    sys.dm_db_xtp_index_stats s
        JOIN sys.indexes i ON s.object_id = i.object_id
                              AND s.index_id = i.index_id
WHERE   OBJECT_ID('<memory-optimized table name>') = s.object_id;
GO


/*Listing 6-1: Create the LoggingDemo database.*/
USE master
GO
IF DB_ID('LoggingDemo')IS NOT NULL
      DROP DATABASE LoggingDemo;
GO
CREATE DATABASE LoggingDemo ON  
    PRIMARY (NAME = [LoggingDemo_data], 
      FILENAME = 'C:\DataHK\LoggingDemo_data.mdf'), 
      FILEGROUP [LoggingDemo_FG] CONTAINS MEMORY_OPTIMIZED_DATA
          (NAME = [LoggingDemo_container1],
           FILENAME = 'C:\DataHK\LoggingDemo_container1')
    LOG ON (name = [LoggingDemo_log], 
            Filename='C:\DataHK\LoggingDemo.ldf', size= 100 MB);
GO

/*Listing 6-2: Create the t1_inmem and t1_disk tables.*/
USE LoggingDemo
GO
IF OBJECT_ID('t1_inmem') IS NOT NULL
      DROP TABLE [dbo].[t1_inmem]
GO

-- create a simple memory-optimized table
CREATE TABLE [dbo].[t1_inmem]
    ( [c1] int NOT NULL, 
      [c2] char(100) NOT NULL,  
      CONSTRAINT [pk_index91] PRIMARY KEY NONCLUSTERED HASH ([c1])
                                      WITH(BUCKET_COUNT = 1000000)
    ) WITH (MEMORY_OPTIMIZED = ON, 
            DURABILITY = SCHEMA_AND_DATA);
GO

IF OBJECT_ID('t1_disk') IS NOT NULL
      DROP TABLE [dbo].[t1_disk]
GO
-- create a similar disk-based table
CREATE TABLE [dbo].[t1_disk]
    ( [c1] int NOT NULL, 
      [c2] char(100) NOT NULL)
GO
CREATE UNIQUE NONCLUSTERED INDEX t1_disk_index on t1_disk(c1);
GO


/*Listing 6-3: Populate the disk-based table with 100 rows and examine the log.*/
SET NOCOUNT ON;
GO
BEGIN TRAN
DECLARE @i INT = 0
WHILE ( @i < 100 )
    BEGIN
        INSERT  INTO t1_disk
        VALUES  ( @i, REPLICATE('1', 100) )
        SET @i = @i + 1
    END
COMMIT

-- you will see that SQL Server logged 200 log records
SELECT  *
FROM    sys.fn_dblog(NULL, NULL)
WHERE   PartitionId IN ( SELECT partition_id
                         FROM   sys.partitions
                         WHERE  object_id = OBJECT_ID('t1_disk') )
ORDER BY [Current LSN] ASC;
GO

/*Listing 6-4: Examine the log after populating the memory-optimized tables with 100 rows.*/
BEGIN TRAN
DECLARE @i INT = 0
WHILE ( @i < 100 )
    BEGIN
        INSERT  INTO t1_inmem
        VALUES  ( @i, REPLICATE('1', 100) )
        SET @i = @i + 1
    END
COMMIT
-- look at the log
SELECT  *
FROM    sys.fn_dblog(NULL, NULL)
ORDER BY [Current LSN] DESC;
GO


/*Listing 6-5: Break apart a LOP_HK log record.*/
SELECT  [current lsn] ,
        [transaction id] ,
        operation ,
        operation_desc ,
        tx_end_timestamp ,
        total_size ,
        OBJECT_NAME(table_id) AS TableName
FROM    sys.fn_dblog_xtp(NULL, NULL)
WHERE   [Current LSN] = '00000020:00000157:0005';
GO

/*Listing 6-6: Create a new database for memory-optimized tables.*/
USE master
GO
IF DB_ID('CkptDemo') IS NOT NULL
    DROP DATABASE CkptDemo;
GO
CREATE DATABASE CkptDemo ON  
   PRIMARY (NAME = [CkptDemo_data], FILENAME = 'C:\DataHK\CkptDemo_data.mdf'), 
   FILEGROUP [CkptDemo_FG] CONTAINS MEMORY_OPTIMIZED_DATA
      (NAME = [CkptDemo_container1],
       FILENAME = 'C:\DataHK\CkptDemo_container1')
 LOG ON (name = [CkptDemo_log], 
         Filename='C:\DataHK\CkptDemo.ldf', size= 100 MB);
GO


/*Listing 6-7: Turn on Trace Flag 9851 to inhibit automatic merging of checkpoint files.*/
DBCC TRACEON (9851, -1);

-- set the database to full recovery.  
ALTER DATABASE CkptDemo SET RECOVERY FULL;
GO


/*Listing 6-8: Create the t_memopt memory-optimized table.*/
USE CkptDemo;
GO
-- create a memory-optimized table with each row of size > 8KB
CREATE TABLE dbo.t_memopt (
       c1 int NOT NULL,
       c2 char(40) NOT NULL,
       c3 char(8000) NOT NULL,
       CONSTRAINT [pk_t_memopt_c1] PRIMARY KEY NONCLUSTERED HASH (c1) 
        WITH (BUCKET_COUNT = 100000)
) WITH (MEMORY_OPTIMIZED = ON, DURABILITY = SCHEMA_AND_DATA);
GO


/*Listing 6-9: Examine the metadata for the checkpoint files.*/
SELECT  file_type_desc ,
        state_desc ,
        internal_storage_slot ,
        file_size_in_bytes ,
        inserted_row_count ,
        deleted_row_count ,
        lower_bound_tsn ,
        upper_bound_tsn ,
        checkpoint_file_id ,
        relative_file_path
FROM    sys.dm_db_xtp_checkpoint_files
ORDER BY file_type_desc ,
        state_desc ,
        lower_bound_tsn;
GO

/*Listing 6-10: Examine the metadata for your checkpoint files.*/
SELECT  file_type_desc ,
        state_desc ,
        relative_file_path
FROM    sys.dm_db_xtp_checkpoint_files
ORDER BY file_type_desc
GO


/*Listing 6-11: Populate the memory-optimized tables with 8000 rows and back up the database.*/
-- INSERT 8000 rows. 
-- This should load 5 16MB data files on a machine with <= 16GB of memory.
SET NOCOUNT ON;
DECLARE @i INT = 0
WHILE ( @i < 8000 )
    BEGIN
        INSERT  t_memopt
        VALUES  ( @i, 'a', REPLICATE('b', 8000) )
        SET @i += 1;
    END;
GO

BACKUP DATABASE [CkptDemo] TO  DISK = N'C:\BackupsHK\CkptDemo_data.bak'
    WITH NOFORMAT, INIT,  NAME = N'CkptDemo-Full Database Backup', SKIP,
         NOREWIND, NOUNLOAD,  STATS = 10;
GO


/*Listing 6-12: Manual checkpoint in the CkptDemo database.*/
CHECKPOINT;
GO
-- now rerun Listing 6-11


/*Listing 6-13: Delete half the rows in the memory-optimized table.*/
SET NOCOUNT ON;
DECLARE @i INT = 0;
WHILE ( @i <= 8000 )
    BEGIN
        DELETE  t_memopt
        WHERE   c1 = @i;
        SET @i += 2;
    END;
GO
CHECKPOINT;
GO


/*Listing 6-14: Force a manual merge of checkpoint files.*/
EXEC sys.sp_xtp_merge_checkpoint_files 'CkptDemo', 1877, 12007
GO

/*Listing 6-15: Verify the state of the merge request.*/
SELECT  request_state_desc ,
        lower_bound_tsn ,
        upper_bound_tsn
FROM    sys.dm_db_xtp_merge_requests; 
GO

/*Listing 6-16: Disable Trace Flag 9851.*/
DBCC TRACEOFF (9851, -1);
GO


/*Listing 6-17: Backing up the log.*/
BACKUP LOG [CkptDemo] TO  DISK = N'C:\BackupsHK\CkptDemo_log.bak'
    WITH NOFORMAT, INIT,  NAME = N'CkptDemo-LOG Backup';
GO


/*Listing 6-18: Forcing checkpoint files into the TOMBSTONE state. */
EXEC sp_xtp_checkpoint_force_garbage_collection;
GO

CHECKPOINT
GO


/*Listing 6-19: Forcing checkpoint files to be removed from disk.*/
BACKUP LOG [CkptDemo] TO  DISK = N'C:\BackupsHK\CkptDemo_log.bak'
    WITH NOFORMAT, INIT,  NAME = N'CkptDemo-LOG Backup';
GO
EXEC sp_filestream_force_garbage_collection;
GO


/*Listing 7-1: Display the list of all table and procedure DLLs currently loaded.*/
SELECT  name ,
        description
FROM    sys.dm_os_loaded_modules
WHERE   description = 'XTP Native DLL'
GO

/*Listing 7-2: Create a new data and memory-optimized table.*/
USE master
GO
CREATE DATABASE NativeCompDemo ON 
    PRIMARY (NAME = NativeCompDemo_Data, 
             FILENAME = 'c:\DataHK\NativeCompDemo_Data.mdf',
             SIZE=500MB)
    LOG ON (NAME = NativeCompDemo_log,
            FILENAME = 'c:\DataHK\NativeCompDemo_log.ldf',
            SIZE=500MB);
GO

ALTER DATABASE NativeCompDemo
    ADD FILEGROUP NativeCompDemo_mod_fg
          CONTAINS MEMORY_OPTIMIZED_DATA
GO
-- adjust filename and path as needed
ALTER DATABASE NativeCompDemo
   ADD FILE (name='NativeCompDemo_mod_dir',
             filename='c:\DataHK\NativeCompDemo_mod_dir') 
TO FILEGROUP NativeCompDemo_mod_fg
GO

USE NativeCompDemo
GO
CREATE TABLE dbo.t1
    (
      c1 INT NOT NULL
             PRIMARY KEY NONCLUSTERED ,
      c2 INT
    )
WITH (MEMORY_OPTIMIZED=ON)
GO

-- retrieve the path of the DLL for table t1
SELECT  name ,
        description
FROM    sys.dm_os_loaded_modules
WHERE   name LIKE '%xtp_t_' + CAST(DB_ID() AS VARCHAR(10)) + '_'
        + CAST(OBJECT_ID('dbo.t1') AS VARCHAR(10)) + '.dll'
GO

/*Listing 7-3: Creating a natively compiled procedure.*/
CREATE PROCEDURE dbo.p1
WITH NATIVE_COMPILATION, SCHEMABINDING, EXECUTE AS OWNER
AS
BEGIN ATOMIC
WITH (TRANSACTION ISOLATION LEVEL=snapshot, LANGUAGE=N'us_english')
  DECLARE @i INT = 1000000
  WHILE @i > 0
    BEGIN
        INSERT  dbo.t1
        VALUES  ( @i, @i + 1 )
        SET @i -= 1
    END
END
GO
EXEC dbo.p1
GO


/*Listing 7-4: Creating the xtp_demo database, and a SCHEMA_ONLY memory-optimized table*/
USE master;
GO

IF DB_ID('xtp_demo') IS NOT NULL
 DROP DATABASE xtp_demo;
GO
CREATE DATABASE xtp_demo ON  
       PRIMARY 
              ( NAME = N'xtp_demo_Data', 
                FILENAME = N'c:\DataHK\xtp_demo_Data.mdf'
                 ), 
       FILEGROUP [xtp_demo_mod] 
              CONTAINS MEMORY_OPTIMIZED_DATA
                     ( NAME = N'xtp_demo1_mod', 
                       FILENAME = N'c:\DataHK\xtp_demo1_mod' , 
                       MAXSIZE = 2GB),
                     ( NAME = N'xtp_demo2_mod', 
                       FILENAME = N'd:\DataHK\xtp_demo2_mod' , 
                       MAXSIZE = 2GB)
       LOG ON 
              ( NAME = N'xtp_demo_Log', 
                FILENAME = N'c:\DataHK\xtp_demo_log.ldf'
                 );
GO

USE xtp_demo;
GO 

------- Create the table -------
CREATE TABLE bigtable_inmem (
       id     uniqueidentifier not null 
              constraint pk_biggerbigtable_inmem primary key nonclustered 
                     hash with( bucket_count = 2097152 ),
 
       account_id           int not null,
       trans_type_id smallint not null,
       shop_id                    int not null,
       trans_made           datetime not null,
       trans_amount  decimal( 20, 2 ) not null,
       entry_date           datetime2 not null default( current_timestamp ),
 
       --index range_trans_type nonclustered 
       -- ( shop_id, trans_type_id, trans_made ),
       --index range_trans_made nonclustered 
       --  ( trans_made, shop_id, account_id ),
       index hash_trans_type nonclustered hash
             ( shop_id, trans_type_id, trans_made )
               with( bucket_count = 2097152),
       index hash_trans_made nonclustered hash
            ( trans_made, shop_id, account_id )
               with( bucket_count = 2097152)
 
       )  WITH ( MEMORY_OPTIMIZED=ON, 
                       DURABILITY=SCHEMA_ONLY );
GO


/*Listing 7-5: An interop procedure, ins_bigtable, to insert rows into the table.*/
------- Create the procedure -------

CREATE PROC ins_bigtable ( @rows_to_INSERT int )
AS
BEGIN 
       SET nocount on;
 
       DECLARE @i int = 1;
       DECLARE @newid uniqueidentifier
       WHILE @i <= @rows_to_INSERT
       BEGIN
          SET @newid = newid()
          INSERT dbo.bigtable_inmem ( id, account_id, trans_type_id, 
                                 shop_id, trans_made, trans_amount )
             VALUES( @newid, 
                 32767 * rand(), 
                   30 * rand(),
                   100 * rand(),
                   dateadd( second, @i, cast( '20130410' AS datetime ) ), 
                      ( 32767 * rand() ) / 100. ) ;
 
              SET @i = @i + 1;
 
       END
END
GO


/*Listing 7-6: A natively compiled stored procedure, ins_native_bigtable, to insert rows into the table*/
CREATE PROC ins_native_bigtable ( @rows_to_INSERT int )
       with native_compilation, schemabinding, execute AS owner
AS
BEGIN ATOMIC WITH
  ( TRANSACTION ISOLATION LEVEL = SNAPSHOT,
    LANGUAGE = N'us_english') 
       DECLARE @i int = 1;
       DECLARE @newid uniqueidentifier
       WHILE @i <= @rows_to_INSERT
       BEGIN
          SET @newid = newid()
          INSERT dbo.bigtable_inmem ( id, account_id, trans_type_id, 
                                 shop_id, trans_made, trans_amount )
             VALUES( @newid, 
                 32767 * rand(), 
                    30 * rand(),
                   100 * rand(),
                   dateadd( second, @i, cast( '20130410' AS datetime ) ), 
                      ( 32767 * rand() ) / 100. ) ;
              SET @i = @i + 1;
       END
END
GO


/*Listing 7-7: Inserting a million rows into a memory-optimized table via ins_bigtable*/
EXEC ins_bigtable @rows_to_INSERT = 1000000;
GO

/*Listing 7-8: Inserting a million rows in a single transaction.*/
DELETE  bigtable_inmem;
GO

BEGIN TRAN
EXEC ins_bigtable @rows_to_INSERT = 1000000;
COMMIT TRAN
GO

/*Listing 7-9: Creating a natively compiled procedure and inserting a million rows.*/
DELETE bigtable_inmem;
GO
EXEC ins_native_bigtable @rows_to_INSERT = 1000000;
GO


/*Listing 8-1: Create a resource pool for a database containing memory-optimized tables.*/
CREATE RESOURCE POOL HkPool 
WITH (MIN_MEMORY_PERCENT=50,
      MAX_MEMORY_PERCENT=50);
ALTER RESOURCE GOVERNOR RECONFIGURE;
GO


/*Listing 8-2: Binding a database to a resource pool.*/
EXEC sp_xtp_bind_db_resource_pool 'HkDB', 'HkPool';
GO

/*Listing 8-3: Taking a database offline and then online to allow memory to be associated with new resource pool.*/
ALTER DATABASE [HkDB] SET OFFLINE;
ALTER DATABASE [HkDB] SET ONLINE;
GO

/*Listing 8-4: Remove the binding between a database and a resource pool.*/
EXEC sp_xtp_unbind_db_resource_pool 'HkDB';
GO

/*Listing 8-5: Report which databases support creation of memory-optimized tables. */
EXEC sp_MSforeachdb 'USE ? IF EXISTS (SELECT 1 FROM sys.filegroups FG 
               JOIN sys.database_files F
                        ON FG.data_space_id = F.data_space_id
     WHERE FG.type = ''FX'' AND F.type = 2) 
             PRINT ''?'' + '' can contain memory-optimized tables.'' ';
GO


/*Listing 8-6: Retrieve package information for in-memory OLTP extended events.*/
SELECT  p.name AS PackageName ,
        COUNT(*) AS NumberOfEvents
FROM    sys.dm_xe_objects o
        JOIN sys.dm_xe_packages p ON o.package_guid = p.guid
WHERE   p.name LIKE 'Xtp%'
GROUP BY p.name;
GO


/*Listing 8-7: Retrieve the names of the in-memory OLTP extended events.*/
SELECT  p.name AS PackageName ,
        o.name AS EventName ,
        o.description AS EventDescription
FROM    sys.dm_xe_objects o
        JOIN sys.dm_xe_packages p ON o.package_guid = p.guid
WHERE   p.name LIKE 'Xtp%';
GO 

/*Listing 8-8: Retrieve the names of the in-memory OLTP performance counters.*/
SELECT  object_name AS ObjectName ,
        counter_name AS CounterName
FROM    sys.dm_os_performance_counters
WHERE   object_name LIKE 'XTP%';
GO


/*Listing 8-9: Creating a memory-optimized table variable using a memory-optimized table type.*/
USE HKDB;
CREATE TYPE SalesOrderDetailType_inmem 
AS TABLE
(
  OrderQty smallint NOT NULL,
  ProductID int NOT NULL,
  SpecialOfferID int NOT NULL,
  LocalID int NOT NULL,
  
  INDEX IX_ProductID  NONCLUSTERED HASH (ProductID) WITH (BUCKET_COUNT = 131072),
  INDEX IX_SpecialOfferID NONCLUSTERED (SpecialOfferID)
)
WITH (MEMORY_OPTIMIZED = ON );
GO
DECLARE @SalesDetail SalesOrderDetailType_inmem;
GO


/*THE END*/











