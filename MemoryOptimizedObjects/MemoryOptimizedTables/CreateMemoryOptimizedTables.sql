-- Create two tables with indexes, one normal table, one as memory optimized
CREATE DATABASE MemoryOptimized
GO
USE MemoryOptimized
ALTER DATABASE MemoryOptimized ADD FILEGROUP TESTING
ALTER DATABASE MemoryOptimized ADD FILE(name='Testing_mod1', FILENAME='d:\Sage\X3ERPV12\Database\data\MemoryOptimizedTesting.mdf') TO FILEGROUP TESTING

ALTER DATABASE MemoryOptimized ADD FILEGROUP MEMORY CONTAINS MEMORY_OPTIMIZED_DATA
ALTER DATABASE MemoryOptimized ADD FILE(name='Memory_mod1', FILENAME='d:\Sage\X3ERPV12\Database\data\MemoryOptimizedMemory.mdf') TO FILEGROUP MEMORY
ALTER DATABASE MemoryOptimized SET MEMORY_OPTIMIZED_ELEVATE_TO_SNAPSHOT=ON

DROP TABLE IF EXISTS SEED.ZAPLLCK
DROP TABLE IF EXISTS SEED.ZAPLLCKMEM
DROP SCHEMA IF EXISTS TESTING
DROP SCHEMA IF EXISTS MEMORY
GO
CREATE SCHEMA TESTING
GO
CREATE SCHEMA MEMORY
GO
/************ Create Table1: ZAPPLCK ************************/
CREATE TABLE [TESTING].[ZAPLLCK](
	[LCKSYM_0] [nvarchar](80) NOT NULL,
	[LCKIND_0] [smallint] NOT NULL,
	[LCKPID_0] [int] NOT NULL,
	[LCKFLG_0] [tinyint] NOT NULL,
	[LCKDAT_0] [datetime] NOT NULL,
	[LCKTIM_0] [int] NOT NULL,
	[ROWID] [numeric](38, 0) IDENTITY(1,1) NOT NULL,
 CONSTRAINT [ZAPLLCK_ROWID] PRIMARY KEY NONCLUSTERED 
	(
		[ROWID] ASC
	) 
) ON [TESTING]
GO


CREATE UNIQUE CLUSTERED INDEX [ZAPLLCK_LCKCLE] ON [TESTING].[ZAPLLCK]
(
	[LCKSYM_0] ASC,
	[LCKIND_0] ASC
)
GO

CREATE NONCLUSTERED INDEX [ZAPLLCK_PIDFLG] ON [TESTING].[ZAPLLCK]
(
	[LCKPID_0] ASC,
	[LCKFLG_0] ASC
)


/************ Create Table1: ZAPPLCK ************************/
CREATE TABLE [MEMORY].[ZAPLLCK](
	[LCKSYM_0] [nvarchar](80) NOT NULL,
	[LCKIND_0] [smallint] NOT NULL,
	[LCKPID_0] [int] NOT NULL,
	[LCKFLG_0] [tinyint] NOT NULL,
	[LCKDAT_0] [datetime] NOT NULL,
	[LCKTIM_0] [int] NOT NULL,
	[ROWID] [numeric](38, 0) IDENTITY(1,1) NOT NULL,
 CONSTRAINT [ZAPLLCK_ROWID] PRIMARY KEY NONCLUSTERED 
	(
		[ROWID] ASC
	) 
) 
--WITH(MEMORY_OPTIMIZED=ON, DURABILITY=SCHEMA_AND_DATA)
WITH(MEMORY_OPTIMIZED=ON, DURABILITY=SCHEMA_ONLY)
GO

ALTER TABLE MEMORY.ZAPLLCK ADD INDEX ZAPLLCK_LCKCLE(LCKSYM_0 ASC, LCKIND_0 ASC)
ALTER TABLE MEMORY.ZAPLLCK ADD INDEX ZAPLLCK_PIDFLG(LCKPID_0 ASC, LCKFLG_0 ASC) 

/************* Insert Data **********************/
SET STATISTICS TIME ON
SET STATISTICS IO ON

ALTER DATABASE MemoryOptimized SET DELAYED_DURABILITY = FORCED

-- INSERT INTO TABLES
INSERT INTO TESTING.ZAPLLCK(LCKDAT_0, LCKFLG_0, LCKIND_0, LCKPID_0, LCKSYM_0, LCKTIM_0)
SELECT TOP 100000 CURRENT_TIMESTAMP, 0, 0, FLOOR(1000 + RAND(CHECKSUM(NEWID())) * 8999), CAST(NEWID() AS VARCHAR(40)), FLOOR(100000 + RAND(CHECKSUM(NEWID())) * 8999)
FROM sys.columns c, sys.columns c2


INSERT INTO MEMORY.ZAPLLCK(LCKDAT_0, LCKFLG_0, LCKIND_0, LCKPID_0, LCKSYM_0, LCKTIM_0)
SELECT TOP 100000 CURRENT_TIMESTAMP, 0, 0, FLOOR(1000 + RAND(CHECKSUM(NEWID())) * 8999), CAST(NEWID() AS VARCHAR(40)), FLOOR(100000 + RAND(CHECKSUM(NEWID())) * 8999)
FROM sys.columns c, sys.columns c2


select * FROM TESTING.ZAPLLCK ORDER BY LCKSYM_0 DESC
select * FROM MEMORY.ZAPLLCK ORDER BY LCKSYM_0 DESC



-- Check Usage
SELECT
   @@SERVERNAME AS [ServerName]
   , DB_NAME() AS [DatabaseName]
   , SCHEMA_NAME([sObj].[schema_id]) AS [SchemaName]
   , [sObj].[name] AS [ObjectName]
   , [sObj].type_desc [ObjectType]
   , [sIdx].is_unique IsUnique
   , [ps].row_count
   , [sIdx].[index_id] AS [IndexID]
   , ISNULL([sIdx].[name], 'N/A') AS [IndexName]
   , [sIdx].type_desc
   , [sdmvIUS].[user_seeks] AS [TotalUserSeeks]
   , [sdmvIUS].[user_scans] AS [TotalUserScans]
   , [sdmvIUS].[user_lookups] AS [TotalUserLookups]
   , [sdmvIUS].[user_seeks] + [sdmvIUS].[user_scans] + [sdmvIUS].[user_lookups] TotalUserSeeksScansLookups
   , [sdmvIUS].[user_updates] AS [TotalUserUpdates]
   , [sdmvIUS].[last_user_seek] AS [LastUserSeek]
   , [sdmvIUS].[last_user_scan] AS [LastUserScan]
   , [sdmvIUS].[last_user_lookup] AS [LastUserLookup]
   , [sdmvIUS].[last_user_update] AS [LastUserUpdate]
   , [sdmfIOPS].[leaf_insert_count] AS [LeafLevelInsertCount]
   , [sdmfIOPS].[leaf_update_count] AS [LeafLevelUpdateCount]
   , [sdmfIOPS].[leaf_delete_count] AS [LeafLevelDeleteCount]
FROM
   [sys].[indexes] AS [sIdx]
   INNER JOIN [sys].[objects] AS [sObj]
      ON [sIdx].[object_id] = [sObj].[object_id]
   LEFT JOIN [sys].[dm_db_partition_stats] ps	-- Stats might not exist
	  ON [sIdx].object_id = [ps].object_id
	  AND [sIdx].index_id = ps.index_id
   LEFT JOIN [sys].[dm_db_index_usage_stats] AS [sdmvIUS]
      ON [sIdx].[object_id] = [sdmvIUS].[object_id]
      AND [sIdx].[index_id] = [sdmvIUS].[index_id]
      AND [sdmvIUS].[database_id] = DB_ID()
   LEFT JOIN [sys].[dm_db_index_operational_stats] (DB_ID(),NULL,NULL,NULL) AS [sdmfIOPS]
      ON [sIdx].[object_id] = [sdmfIOPS].[object_id]
      AND [sIdx].[index_id] = [sdmfIOPS].[index_id]
WHERE
   [sObj].[type] IN ('U','V')         -- Look in Tables & Views
   AND [sObj].[is_ms_shipped] = 0x0   -- Exclude System Generated Objects
   AND [sIdx].[is_disabled] = 0x0     -- Exclude Disabled Indexes
ORDER BY [ServerName], [DatabaseName], [SchemaName], [ObjectName], [IndexID]



SELECT
	Database_ID,
	CONVERT(VARCHAR(35),DB_NAME(idx.database_id)) AS [DB Name],
	sch.name [Schema Name],
	idx.[Object_ID],CONVERT(VARCHAR(35),OBJECT_NAME(idx.[OBJECT_ID])) AS 'OBJECT NAME',
	idx.Partition_Number [Partition Number],
	idx.Index_ID [Index ID],
	idx.Index_Type_Desc [Index Type Desc],
	idx.Alloc_Unit_Type_Desc [Alloc Unit Type Desc],
	idx.Index_Depth,Index_Level [Index Depth Level],
	idx.Avg_Fragmentation_In_Percent [Avg Frag Percent],
	idx.Fragment_Count [Frag Count],
	Avg_Fragment_Size_In_Pages [Avg Frag Size In Pages],
	idx.Page_Count [Page Count],
	idx.Avg_Page_Space_Used_In_Percent [Avg Page Space Used In Percent],
	idx.Record_Count [Record Count],
	Ghost_Record_Count [Ghost Record Count],
	idx.Version_Ghost_Record_Count [Version Ghost Record Count],
	idx.Min_Record_Size_In_Bytes [Min Record Size In Bytes],
	idx.Max_Record_Size_In_Bytes [Max Record Size In Bytes],
	idx.Avg_Record_Size_In_Bytes [Avg Record Size In Bytes],
	Forwarded_Record_Count [Forwarded Record Count]
FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'DETAILED') idx
	INNER JOIN sys.tables t
	ON idx.object_id = t.object_id
	INNER JOIN sys.schemas sch
	ON sch.schema_id = t.schema_id
--WHERE idx.page_count > 100
--	AND idx.avg_fragmentation_in_percent > 15
--	AND idx.Index_ID > 0
ORDER BY idx.avg_fragmentation_in_percent desc



/*
USE master
GO
DROP DATABASE IF EXISTS MemoryOptimized
*/