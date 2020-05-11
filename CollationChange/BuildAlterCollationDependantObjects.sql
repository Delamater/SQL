/******************************************************************************
* Search for columns schemas in the current database for columns with specific collation methods
* Returns Schema, TableName, object type and count of columns per object with said collation method
*/
 
IF OBJECT_ID('uspCheckCollationMethodAggregate', 'IF') IS NOT NULL
BEGIN
    PRINT 'Recreating function dbo.uspCheckCollationMethodAggregate'
    DROP FUNCTION dbo.uspCheckCollationMethodAggregate
END

IF OBJECT_ID('uspCheckCollationMethod', 'IF') IS NOT NULL
BEGIN
    PRINT 'Recreating function dbo.uspCheckCollationMethod'
    DROP FUNCTION dbo.uspCheckCollationMethod
END

IF OBJECT_ID('uspGetColumnInfo', 'IF') IS NOT NULL
BEGIN
    PRINT 'Recreating function dbo.uspGetColumnInfo'
    DROP FUNCTION dbo.uspGetColumnInfo
END

IF OBJECT_ID('dbo.usp_GetErrorInfo', 'P') IS NOT NULL
BEGIN
	PRINT 'Recreating procedure dbo.usp_GetErrorInfo'
	DROP PROCEDURE dbo.usp_GetErrorInfo 
END
GO
 

IF OBJECT_ID('dbo.uspGetDropIndexesByTableSyntax', 'IF') IS NOT NULL
BEGIN
	PRINT 'Recreating function dbo.uspGetDropIndexesByTableSyntax'
	DROP FUNCTION dbo.uspGetDropIndexesByTableSyntax
END

IF OBJECT_ID('dbo.uspGetCreateIndexSyntax', 'IF') IS NOT NULL
BEGIN
	PRINT 'Recreating function dbo.uspGetCreateIndexSyntax'
	DROP FUNCTION dbo.uspGetCreateIndexSyntax
END

-- Create custom type to hold all X3 folders
IF EXISTS
(SELECT * FROM sys.types st JOIN sys.schemas ss ON st.schema_id = ss.schema_id WHERE st.name = N'X3Users' AND ss.name = N'dbo')
BEGIN
    PRINT 'Recreating TYPE dbo.ObjectIDs'
    DROP TYPE [dbo].[X3Users]
END 
 
CREATE TYPE dbo.X3Users AS TABLE
(
    FolderName NVARCHAR(10)
)
 
GO
 


/******************************************************************************	
Description: 
	This procedure will find all columns that are NOT collated as specified
	by the @CollationMethod parameter. 
Parameters: 
	@X3Users: A type of dbo.X3Users, which is a table of X3 users derived from 
			  the parent folder's ADOSSIER table. 
	@CollationMethod: The collation method that the database should be
Returns: 
	A table with the COUNT of columns per table that are 
	not using the collation method of @CollationMethod
******************************************************************************/
CREATE FUNCTION dbo.uspCheckCollationMethodAggregate
	(@X3Users dbo.X3Users READONLY, @CollationMethod SYSNAME) 
	RETURNS TABLE AS RETURN
(
    SELECT  
		c.object_id ObjectID, s.[name] SchemaName, t.[name] TableName, t.[type_desc], 
		COUNT(*) CountOfColumnsInDifferentCollation
    FROM sys.tables t
        INNER JOIN sys.schemas s
            ON t.schema_id = s.schema_id
        INNER JOIN sys.columns c
            ON t.object_id = c.object_id
    WHERE
        s.name IN (SELECT FolderName FROM @X3Users)
        AND LOWER(c.collation_name) <> LOWER(@CollationMethod)
    GROUP BY c.object_id, s.[name], t.[name], t.[type_desc]
)

GO

/******************************************************************************	
Description: 
	This procedure will find all columns that are NOT collated as specified
	by the @CollationMethod parameter. 
Parameters: 
	@X3Users: A type of dbo.X3Users, which is a table of X3 users derived from 
			  the parent folder's ADOSSIER table. 
	@CollationMethod: The collation method that the database should be
Returns: 
	A table listing each column not using the collation 
	method of @CollationMethod
******************************************************************************/
CREATE FUNCTION dbo.uspCheckCollationMethod
	(@X3Users X3Users READONLY, @CollationMethod SYSNAME) 
	RETURNS TABLE AS RETURN 
(
    SELECT  
		c.object_id ObjectID, s.[name] SchemaName, t.[name] TableName, t.[type_desc], 
		c.name ColumnName, c.collation_name
    FROM sys.tables t
        INNER JOIN sys.schemas s
            ON t.schema_id = s.schema_id
        INNER JOIN sys.columns c
            ON t.object_id = c.object_id
    WHERE
        s.name IN (SELECT FolderName FROM @X3Users)
        AND LOWER(c.collation_name) <> LOWER(@CollationMethod)
)
GO
/******************************************************************************	
Description: 
	This procedure will find all columns that are NOT collated as specified
	by the @CollationMethod parameter. 
Parameters: 
	@schema: A type of dbo.X3Users, which is a table of X3 users derived from 
			  the parent folder's ADOSSIER table. 
	@TablePattern: The collation method that the database should be
Returns: 
	A table listing each column not using the collation 
	method of @CollationMethod
******************************************************************************/
CREATE FUNCTION dbo.uspGetColumnInfo(@schema dbo.X3Users READONLY, @TablePattern SYSNAME) RETURNS TABLE AS RETURN
(
	SELECT 
	  f.column_ordinal ID, 
	  f.name [ColumnName], 
	  f.collation_name,
	  f.system_type_name [Type], 
	  [Nullable]  = 
		CASE f.is_nullable
			WHEN 0 THEN 'NOT NULL'
			WHEN 1 THEN 'NULL'
		END,
	  QUOTENAME(s.name) + N'.' + QUOTENAME(t.name) SourceTable,
	  s.name SchemaName,
	  t.name TableName
	FROM sys.tables AS t 
		INNER JOIN sys.schemas AS s
		ON t.[schema_id] = s.[schema_id]
	CROSS APPLY sys.dm_exec_describe_first_result_set
	(
		CONCAT(N'SELECT * FROM ', QUOTENAME(s.name), N'.', QUOTENAME(t.name)), NULL, 0
    
	) AS f
	WHERE 
		t.name LIKE @TablePattern 
		AND s.[name] IN(SELECT FolderName FROM @schema)
	--ORDER BY SourceTable,ID;	
)
GO
CREATE PROCEDURE dbo.usp_GetErrorInfo  
AS  
SELECT  
    ERROR_NUMBER() AS ErrorNumber  
    ,ERROR_SEVERITY() AS ErrorSeverity  
    ,ERROR_STATE() AS ErrorState  
    ,ERROR_PROCEDURE() AS ErrorProcedure  
    ,ERROR_LINE() AS ErrorLine  
    ,ERROR_MESSAGE() AS ErrorMessage;  
GO  


/******************************************************************************	
Description: 
	This procedure will find all indexes to drop for a given schema.table
Parameters: 
	@schema: A type of dbo.X3Users, which is a table of X3 users derived from 
			  the parent folder's ADOSSIER table. 
	@TablePattern: The collation method that the database should be
Returns: 
	A table listing each column not using the collation 
	method of @CollationMethod
******************************************************************************/
CREATE FUNCTION dbo.uspGetDropIndexesByTableSyntax(@schemaName SYSNAME, @tableName SYSNAME) RETURNS TABLE AS RETURN
(
	-- Get indexes
	SELECT s.name SchemaName, t.name TableName, i.name IndexName, i.object_id IndexObjectID, CONCAT('DROP INDEX ', i.name, ' ON ', s.name, '.', t.name) DropSyntax
	FROM sys.tables t
		INNER JOIN sys.schemas s
			ON t.schema_id = s.schema_id
		INNER JOIN sys.indexes i
			ON t.object_id = i.object_id
	WHERE 
		s.name = @schemaName
		AND t.name = @tableName
		AND i.name NOT LIKE '%ROWID%'
)

GO

CREATE FUNCTION dbo.uspGetCreateIndexSyntax(@folder SYSNAME, @tablePattern SYSNAME) 
	RETURNS TABLE AS RETURN
(
	SELECT 
		DB_NAME() AS database_name,
		sc.name + N'.' + t.name AS table_name,
		--(SELECT MAX(user_reads) 
		--    FROM (VALUES (last_user_seek), (last_user_scan), (last_user_lookup)) AS value(user_reads)) AS last_user_read,
		--last_user_update,
		CASE si.index_id WHEN 0 THEN N'/* No create statement (Heap) */'
		ELSE 
			CASE is_primary_key WHEN 1 THEN
				N'ALTER TABLE ' + QUOTENAME(sc.name) + N'.' + QUOTENAME(t.name) + N' ADD CONSTRAINT ' + QUOTENAME(si.name) + N' PRIMARY KEY ' +
					CASE WHEN si.index_id > 1 THEN N'NON' ELSE N'' END + N'CLUSTERED '
				ELSE N'CREATE ' + 
					CASE WHEN si.is_unique = 1 then N'UNIQUE ' ELSE N'' END +
					CASE WHEN si.index_id > 1 THEN N'NON' ELSE N'' END + N'CLUSTERED ' +
					N'INDEX ' + QUOTENAME(si.name) + N' ON ' + QUOTENAME(sc.name) + N'.' + QUOTENAME(t.name) + N' '
			END +
			/* key def */ N'(' + key_definition + N')' +
			/* includes */ CASE WHEN include_definition IS NOT NULL THEN 
				N' INCLUDE (' + include_definition + N')'
				ELSE N''
			END +
			/* filters */ CASE WHEN filter_definition IS NOT NULL THEN 
				N' WHERE ' + filter_definition ELSE N''
			END +
			/* with clause - compression goes here */
			CASE WHEN row_compression_partition_list IS NOT NULL OR page_compression_partition_list IS NOT NULL 
				THEN N' WITH (' +
					CASE WHEN row_compression_partition_list IS NOT NULL THEN
						N'DATA_COMPRESSION = ROW ' + CASE WHEN psc.name IS NULL THEN N'' ELSE + N' ON PARTITIONS (' + row_compression_partition_list + N')' END
					ELSE N'' END +
					CASE WHEN row_compression_partition_list IS NOT NULL AND page_compression_partition_list IS NOT NULL THEN N', ' ELSE N'' END +
					CASE WHEN page_compression_partition_list IS NOT NULL THEN
						N'DATA_COMPRESSION = PAGE ' + CASE WHEN psc.name IS NULL THEN N'' ELSE + N' ON PARTITIONS (' + page_compression_partition_list + N')' END
					ELSE N'' END
				+ N')'
				ELSE N''
			END +
			/* ON where? filegroup? partition scheme? */
			' ON ' + CASE WHEN psc.name is null 
				THEN ISNULL(QUOTENAME(fg.name),N'')
				ELSE psc.name + N' (' + partitioning_column.column_name + N')' 
				END
			+ N';'
		END AS index_create_statement,
		si.index_id,
		si.name AS index_name
		--partition_sums.reserved_in_row_GB,
		--partition_sums.reserved_LOB_GB,
		--partition_sums.row_count,
		--stat.user_seeks,
		--stat.user_scans,
		--stat.user_lookups,
		--user_updates AS queries_that_modified,
		--partition_sums.partition_count,
		--si.allow_page_locks,
		--si.allow_row_locks,
		--si.is_hypothetical,
		--si.has_filter,
		--si.fill_factor,
		--si.is_unique,
		--ISNULL(pf.name, '/* Not partitioned */') AS partition_function,
		--ISNULL(psc.name, fg.name) AS partition_scheme_or_filegroup,
		--t.create_date AS table_created_date,
		--t.modify_date AS table_modify_date
	FROM sys.indexes AS si
	JOIN sys.tables AS t ON si.object_id=t.object_id
	JOIN sys.schemas AS sc ON t.schema_id=sc.schema_id
	LEFT JOIN sys.dm_db_index_usage_stats AS stat ON 
		stat.database_id = DB_ID() 
		and si.object_id=stat.object_id 
		and si.index_id=stat.index_id
	LEFT JOIN sys.partition_schemes AS psc ON si.data_space_id=psc.data_space_id
	LEFT JOIN sys.partition_functions AS pf ON psc.function_id=pf.function_id
	LEFT JOIN sys.filegroups AS fg ON si.data_space_id=fg.data_space_id
	/* Key list */ OUTER APPLY ( SELECT STUFF (
		(SELECT N', ' + QUOTENAME(c.name) +
			CASE ic.is_descending_key WHEN 1 then N' DESC' ELSE N'' END
		FROM sys.index_columns AS ic 
		JOIN sys.columns AS c ON 
			ic.column_id=c.column_id  
			and ic.object_id=c.object_id
		WHERE ic.object_id = si.object_id
			and ic.index_id=si.index_id
			and ic.key_ordinal > 0
		ORDER BY ic.key_ordinal FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'),1,2,'')) AS keys ( key_definition )
	/* Partitioning Ordinal */ OUTER APPLY (
		SELECT MAX(QUOTENAME(c.name)) AS column_name
		FROM sys.index_columns AS ic 
		JOIN sys.columns AS c ON 
			ic.column_id=c.column_id  
			and ic.object_id=c.object_id
		WHERE ic.object_id = si.object_id
			and ic.index_id=si.index_id
			and ic.partition_ordinal = 1) AS partitioning_column
	/* Include list */ OUTER APPLY ( SELECT STUFF (
		(SELECT N', ' + QUOTENAME(c.name)
		FROM sys.index_columns AS ic 
		JOIN sys.columns AS c ON 
			ic.column_id=c.column_id  
			and ic.object_id=c.object_id
		WHERE ic.object_id = si.object_id
			and ic.index_id=si.index_id
			and ic.is_included_column = 1
		ORDER BY c.name FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'),1,2,'')) AS includes ( include_definition )
	/* Partitions */ OUTER APPLY ( 
		SELECT 
			COUNT(*) AS partition_count,
			CAST(SUM(ps.in_row_reserved_page_count)*8./1024./1024. AS NUMERIC(32,1)) AS reserved_in_row_GB,
			CAST(SUM(ps.lob_reserved_page_count)*8./1024./1024. AS NUMERIC(32,1)) AS reserved_LOB_GB,
			SUM(ps.row_count) AS row_count
		FROM sys.partitions AS p
		JOIN sys.dm_db_partition_stats AS ps ON
			p.partition_id=ps.partition_id
		WHERE p.object_id = si.object_id
			and p.index_id=si.index_id
		) AS partition_sums
	/* row compression list by partition */ OUTER APPLY ( SELECT STUFF (
		(SELECT N', ' + CAST(p.partition_number AS VARCHAR(32))
		FROM sys.partitions AS p
		WHERE p.object_id = si.object_id
			and p.index_id=si.index_id
			and p.data_compression = 1
		ORDER BY p.partition_number FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'),1,2,'')) AS row_compression_clause ( row_compression_partition_list )
	/* data compression list by partition */ OUTER APPLY ( SELECT STUFF (
		(SELECT N', ' + CAST(p.partition_number AS VARCHAR(32))
		FROM sys.partitions AS p
		WHERE p.object_id = si.object_id
			and p.index_id=si.index_id
			and p.data_compression = 2
		ORDER BY p.partition_number FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'),1,2,'')) AS page_compression_clause ( page_compression_partition_list )
	WHERE 
		si.type IN (0,1,2) /* heap, clustered, nonclustered */
		AND si.name is not null
		AND si.name NOT LIKE '%ROWID%'
		AND sc.name IN (@folder)
		AND t.name LIKE @tablePattern
	--ORDER BY table_name, si.index_id
	--OPTION (RECOMPILE);
)
