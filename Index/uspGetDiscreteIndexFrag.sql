/********************************************************************************************************
Author:			Bob Delamater																		
	Date:			05/25/2015																		
	Description:	This procedure has a specific purpose, to report index fragmentation for a specific	
					set of tables. It is true, you can easily run the index fragmentation query for all	
					indexes in your database. However, there are times when you are troubleshooting		
					a performance issue with a specific function in your application, which relies on	
					a discrete set of tables only. It would be unwise to run the index fragmentation	
					query for all tables in this scenario for a couple reasons:							
						1. You don't need index fragmentation for most of the tables that are returned	
						2. Checking fragmentation on all tables can be a big burden on SQL Server		
																										
					In addition, this query also brings back the row count for the table.				
																										
	Dependencies:	dbo.uspGetDiscreteIndexFrag relies on dbo.ObjectIDs, a database "type" object.		
																										
	Parameters:		@ObjectIDs	INT																		
						-This is the set of tables, expressed as an objectid that you want				
						fragmentation information about													
					@FragPercent INT																	
						- This is the minimum fragmentation an index must have in order for it to be	
						returned within the result set													
					@PageCount	INT																		
						- THis is the minimum page count an index must have in order for it to be		
						returned within the result set													
					@Rebuild	BIT	(FOR FUTURE USE, NOT IMPLEMENTED TODAY)																	
						- Set this to 1 if you want to execute a rebuild on these indexes				
						- Set this to 0 if you do not want to execute a rebuild on these indexes		
																										
	Execution Instructions:																				
					This stored procedure takes an array (or table) of objectIDs in order to process
					results. Set up the driver table like the following:

					-- Make reference to the objectIDs type
					DECLARE  @ObjectIDs AS dbo.ObjectIDs 

					-- Insert into the driver table with any type of range of tables you require 
					--	(see WHERE clause below)
					DECLARE  @ObjectIDs AS dbo.ObjectIDs ;

					INSERT INTO @ObjectIDs(ObjectId, SchemaName, TableName)
					SELECT t.object_id, s.name, t.name
					FROM sys.tables t
						INNER JOIN sys.schemas s
							ON t.schema_id = s.schema_id
					WHERE 
						t.name = 'Person'
						AND s.name = 'Person'

					exec [uspGetDiscreteIndexFrag] @ObjectIDs, 0, 0



*********************************************************************************************************/

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[uspGetDiscreteIndexFrag]') AND type in (N'P', N'PC'))
BEGIN
	PRINT 'Recreating procedure uspGetDiscreteIndexFrag'
	DROP PROCEDURE [dbo].[uspGetDiscreteIndexFrag]
END
GO

IF EXISTS 
(SELECT * FROM sys.types st JOIN sys.schemas ss ON st.schema_id = ss.schema_id WHERE st.name = N'ObjectIDs' AND ss.name = N'dbo')
BEGIN
	PRINT 'Recreating TYPE dbo.ObjectIDs'
	DROP TYPE [dbo].[ObjectIDs]
END



GO
CREATE TYPE dbo.ObjectIDs AS TABLE 
(
	ObjectId INT, 
	SchemaName	SYSNAME,
	TableName	SYSNAME
)

GO

CREATE PROCEDURE dbo.uspGetDiscreteIndexFrag @Objs ObjectIDs READONLY, @FragPercent INT, @PageCount INT AS
BEGIN
	SET NOCOUNT ON

	-- Create the output table
	CREATE TABLE #FragOutput
	(
		DatabaseID					INT,
		DbName						SYSNAME,
		SchemaName					SYSNAME,
		ObjectID					INT,
		ObjectName					VARCHAR(MAX),
		PartitionNumber				INT,
		IndexID						INT,
		IndexName					SYSNAME,
		IndexTypeDesc				VARCHAR(MAX),
		AllocUnitTypeDesc			VARCHAR(MAX),
		IndexDepth					SMALLINT,
		IndexDepthLevel				SMALLINT,
		AvgFragPercent				DECIMAL(18,10),
		FragCount					INT,
		AvgFragSizeInPages			DECIMAL(18,10),
		[PageCount]					INT,
		AvgPageSpaceUsedInPercent	DECIMAL(18,10),
		IndexRecordCount			INT,
		GhostRecordCount			INT,
		VersionGhostRecordCount		INT,
		MinRecordSizeInBytes		INT,
		MaxRecordSizeInBytes		INT,
		AvgRecordSizeInBytes		DECIMAL(18,10),
		ForwardedRecordCount		INT,
		TableRowCount				INT
		--RebuildStatment				VARCHAR(MAX)

	)
		
-- For every object id in the driver table, report fragmentation for all indexes for that table

	DECLARE getFrag CURSOR
	READ_ONLY
	FOR SELECT ObjectId, SchemaName, TableName FROM @Objs

	DECLARE @ObjectID INT, @SchemaName SYSNAME, @TableName SYSNAME
	OPEN getFrag

	FETCH NEXT FROM getFrag INTO @ObjectID, @SchemaName, @TableName
	WHILE (@@fetch_status <> -1)
	BEGIN
		IF (@@fetch_status <> -2)
		BEGIN
			INSERT INTO #FragOutput
			SELECT
				database_id, 
				CONVERT(VARCHAR(35),DB_NAME(idx.database_id)) AS [DB Name],
				sch.name,
				idx.[object_id],
				CONVERT(VARCHAR(35),OBJECT_NAME(idx.[object_id])),
				idx.partition_number,
				idx.index_id, 
				(SELECT name FROM sys.indexes WHERE object_id = t.object_id AND index_id = idx.index_id),
				--i.name,
				idx.index_type_desc,
				idx.alloc_unit_type_desc,
				idx.index_depth,
				idx.index_level,
				idx.avg_fragmentation_in_percent,
				idx.fragment_count,
				avg_fragment_size_in_pages,
				idx.page_count,
				idx.avg_page_space_used_in_percent,
				idx.record_count,
				ghost_record_count,
				idx.version_ghost_record_count,
				idx.min_record_size_in_bytes,
				idx.max_record_size_in_bytes,
				idx.avg_record_size_in_bytes,
				forwarded_record_count, 
				(
					SELECT CAST(p.rows AS float)
					FROM sys.tables AS tbl
						INNER JOIN sys.indexes AS idx 
							ON idx.object_id = tbl.object_id 
							AND idx.index_id < 2
						INNER JOIN sys.partitions AS p 
							ON p.object_id=CAST(tbl.object_id AS int)
							AND p.index_id=idx.index_id
					WHERE ((tbl.name=@TableName
					AND SCHEMA_NAME(tbl.schema_id)=@SchemaName))
				) -- RowCount 
				--'ALTER INDEX ' + i.name + ' ON ' + sch.name+ '.' + t.name + ' REBUILD' -- Rebuild Statement
			FROM sys.dm_db_index_physical_stats(DB_ID(), @ObjectID, NULL, NULL,'DETAILED') idx
				INNER JOIN sys.tables t
					ON idx.object_id = t.object_id
				INNER JOIN sys.schemas sch
					ON sch.schema_id = t.schema_id
				--INNER JOIN sys.indexes i
				--	ON t.object_id = i.object_id
			WHERE idx.page_count > @PageCount 
				AND idx.avg_fragmentation_in_percent > @FragPercent
				AND idx.index_id > 0
			ORDER BY idx.avg_fragmentation_in_percent desc
		END
		FETCH NEXT FROM getFrag INTO @ObjectID, @SchemaName, @TableName
	END
	
	CLOSE getFrag
	DEALLOCATE getFrag

	
	SELECT 
		DbName, SchemaName, ObjectID, ObjectName, 
		TableRowCount, IndexRecordCount, [PageCount], 
		IndexTypeDesc, IndexID, IndexName, IndexDepth, IndexDepthLevel,
		AvgFragPercent
		
	FROM #FragOutput 
	ORDER BY SchemaName, OBJECT_NAME(ObjectID), IndexName, IndexDepth, IndexDepthLevel
	
	
	--IF @Rebuild = 1
	--BEGIN
			
	--	DECLARE indexRebuild CURSOR READ_ONLY FOR 
	--	SELECT RebuildStatment
	--	FROM #FragOutput

	--	DECLARE @sqlToExecute VARCHAR(MAX)
	--	OPEN indexRebuild

	--	FETCH NEXT FROM indexRebuild INTO @sqlToExecute
	--	WHILE (@@fetch_status <> -1)
	--	BEGIN
	--		IF (@@fetch_status <> -2)
	--		BEGIN			
	--			EXEC(@sqlToExecute)
	--		END

	--		FETCH NEXT FROM indexRebuild INTO @sqlToExecute
	--	END

	--END
	
	 
	DROP TABLE #FragOutput

	SET NOCOUNT OFF
END


