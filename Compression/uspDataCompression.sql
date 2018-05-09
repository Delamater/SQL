IF OBJECT_ID('uspDataCompression') IS NOT NULL
BEGIN
	DROP PROCEDURE uspDataCompression
	PRINT 'Dropping procedure uspDataCompression'
END
GO

/*******************************************************************************************************************
Author: Bob Delamater
Date: 05/09/2018
Description:
 Estimate requested space savings of entire database for a particular compression type. 
 Store the results into a permentant table which you can query

Execute Example:
	exec uspDataCompression @CompressionType = 'ROW', @Compress = 0, @SchemaName = 'SEED'
	exec uspDataCompression @CompressionType = 'PAGE', @Compress = 0, @SchemaName = 'SEED'

Sample Query Against Results:
	WITH cte(schemaName, objectName, CompressionType, SumOfCurrentCompressionSetting_MB, SumWithRequestedCompressionSetting_MB, Savings_MB) AS
	(
		SELECT [schema_name], [object_name], [Compression_Type],
			(SUM(CAST([size_with_current_compression_setting_KB] AS DECIMAL(10,3)))) / 1024 SumOfCurrentCompressionSetting_MB,
			(SUM(CAST([size_with_requested_compression_setting_KB] AS DECIMAL(10,3)))) / 1024 SumWithRequestedCompressionSetting_MB,
			(SUM(CAST([size_with_current_compression_setting_KB] AS DECIMAL(10,3))) - SUM(CAST([size_with_requested_compression_setting_KB] AS DECIMAL(10,3)))) / 1024 Savings_MB
		FROM dbo.CompressionFacts
		WHERE [schema_name] = 'X3PERF'
		GROUP BY [schema_name], [object_name], [Compression_Type]
		--ORDER BY [schema_name], [object_name], [Compression_Type]
	)
	SELECT 
		*
	FROM cte
******************************************************************************************************************/
CREATE PROCEDURE uspDataCompression (@CompressionType VARCHAR(10), @Compress BIT, @SchemaName SYSNAME) AS
SET NOCOUNT ON
/*** Table Set Up *********************************************************/
IF OBJECT_ID('dbo.CompressionFacts') IS NULL
BEGIN 
	PRINT 'Creating Compression Fact Table'
	CREATE TABLE dbo.CompressionFacts
	(
		ID														INT IDENTITY(1,1) PRIMARY KEY,
		[Compression_Type]										VARCHAR(10),
		[object_name]											SYSNAME,
		[schema_name]											SYSNAME,
		[index_id]												INT,
		[partition_number]										INT,
		[size_with_current_compression_setting_KB]				BIGINT,
		[size_with_requested_compression_setting_KB]			BIGINT,
		[sample_size_with_current_compression_setting_KB]		BIGINT,
		[sample_size_with_requested_compression_setting_KB]		BIGINT,
		InsertGUID												UNIQUEIDENTIFIER,
		InsertDate												DATETIME2
	)
END

DECLARE @tmp TABLE
(
	[object_name]											SYSNAME,
	[schema_name]											SYSNAME,
	[index_id]												INT,
	[partition_number]										INT,
	[size_with_current_compression_setting_KB]				BIGINT,
	[size_with_requested_compression_setting_KB]			BIGINT,
	[sample_size_with_current_compression_setting_KB]		BIGINT,
	[sample_size_with_requested_compression_setting_KB]		BIGINT
)

/*** Cursor Set Up *********************************************************/
DECLARE AllTables CURSOR READ_ONLY FOR
SELECT t.name
FROM sys.tables t
	INNER JOIN sys.schemas s
		ON t.schema_id = s.schema_id
WHERE s.name = @SchemaName 


DECLARE @TableName SYSNAME
DECLARE @sqlstmt VARCHAR(MAX)
OPEN AllTables


FETCH NEXT FROM AllTables INTO @TableName
WHILE (@@FETCH_STATUS <> -1)
BEGIN
	
	IF @Compress = 0
	BEGIN
		PRINT 'Checking: ' + CAST(@TableName AS VARCHAR(MAX))
		INSERT INTO @tmp
		exec sys.sp_estimate_data_compression_savings  @SchemaName, @TableName,NULL,1,@CompressionType
	END
	ELSE
	BEGIN
		SET @sqlstmt = 'ALTER TABLE [' +  @SchemaName + '].[' + @TableName + ' REBUILD PARTITION = ALL WITH (DATA_COMPRESSION = ' + @CompressionType
		--exec(@sqlstmt)
		PRINT @sqlstmt
	END
	
	FETCH NEXT FROM AllTables INTO @TableName
END

CLOSE AllTables
DEALLOCATE AllTables

DECLARE @InsertGuid UNIQUEIDENTIFIER, @InsertDate DATETIME2
SET @InsertGuid = NEWID()
SET @InsertDate = GETDATE()

INSERT INTO dbo.CompressionFacts
	(Compression_Type, object_name, schema_name, index_id, partition_number, 
	[size_with_current_compression_setting_KB],
	[size_with_requested_compression_setting_KB],
	[sample_size_with_current_compression_setting_KB],
	[sample_size_with_requested_compression_setting_KB],
	InsertGUID, InsertDate)

SELECT 
	@CompressionType,object_name, schema_name, index_id, partition_number, 
	[size_with_current_compression_setting_KB],
	[size_with_requested_compression_setting_KB],
	[sample_size_with_current_compression_setting_KB],
	[sample_size_with_requested_compression_setting_KB],
	@InsertGuid, @InsertDate
FROM @tmp
