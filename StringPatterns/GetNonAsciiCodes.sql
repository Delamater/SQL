/********************************************************************************************************
Author:				Bob Delamater
Date:				02/24/2016
Description:		This procedure will find any ascii characters in a collection of tables you pass in. 
					This procedure is not optimized for speed. IsContainsNonAscii processes using 
					the following logic:
					
					1. Loop through all the tables passed in
					2. For each table, learn all the columns that are a type of string
					3. For each column in that table, search all the rows in that column.
					Any field that has a special character will have the database name, schema name, 
					table name, column name, and column value recorded to permenant results table, 
					which you can query afterwards.

Dependencies:
					1. Function:	dbo.IsContainsNonAscii
					2. Table:		dbo.AsciiSearchResults
					3. Custom Type:	ObjectIds

Execution Instructions:


DECLARE @ObjectIDs AS dbo.ObjectIds
INSERT INTO @ObjectIDs(ObjectID, SchemaName, TableName)
SELECT t.object_id, s.name, t.name
FROM sys.tables t
	INNER JOIN sys.schemas s
		ON s.schema_id = t.schema_id
		AND t.name IN
		(
			'BPCUSTOMER', 'CONTACT', 'CONTACTCRM'
		)
WHERE s.name = 'SEED'

EXEC uspFindNonAsciiFields @ObjectIDs, @MinAscii = 31, @MaxAscii = 126

*********************************************************************************************************/



/****************************** Drop all objects ****************************/
IF OBJECT_ID('uspFindNonAsciiFields', 'P') IS NOT NULL
BEGIN
	PRINT 'Dropping procedure: uspFindNonAsciiFields'
	DROP PROCEDURE dbo.uspFindNonAsciiFields
END

GO

IF EXISTS(SELECT * FROM sys.types WHERE is_table_type = 1 AND name = 'ObjectIds')
BEGIN
	PRINT 'Dropping type: dbo.ObjectIds'
	DROP TYPE dbo.ObjectIds
END

GO

IF OBJECT_ID('dbo.IsContainsNonAscii', 'FN') IS NOT NULL
BEGIN
	PRINT 'Dropping function: dbo.IsContainsNonAscii '
	DROP FUNCTION dbo.IsContainsNonAscii 
END
GO

/****************************** Create Function: IsContainsNonAscii ****************************/
CREATE FUNCTION dbo.IsContainsNonAscii ( @string nvarchar(max), @minAscii INT, @maxAscii INT ) 
RETURNS BIT AS 
BEGIN

	DECLARE @pos		INT = 0;
	declare @char		NVARCHAR(1);
	declare @retval		BIT = 0;

	WHILE @pos < DATALENGTH(@string)
	BEGIN
		SELECT @char = SUBSTRING(@string, @pos, 1)
		IF ASCII(@char) <= @minAscii  or ASCII(@char) >= @maxAscii 
			BEGIN
				SELECT @retval = 1;
				RETURN @retval;
			END
		ELSE
			BEGIN
				SELECT @pos = @pos + 1
			END
	END

	RETURN @retval;
END

GO

/****************************** Custom Type: ObjectIDs ****************************/
CREATE TYPE dbo.ObjectIds AS TABLE
(
	ObjectID		INT,
	SchemaName		SYSNAME,
	TableName		SYSNAME
)

GO

/****************************** Stored Procedure Creation ****************************/
CREATE PROCEDURE dbo.uspFindNonAsciiFields @Objs ObjectIds READONLY, @MinAscii INT = 31, @MaxAscii INT = 127 AS

SET NOCOUNT ON

	IF OBJECT_ID('dbo.AsciiSearchResults', 'U') IS NULL
	BEGIN
		PRINT 'Creating table dbo.AsciiSearchResults'
		CREATE TABLE dbo.AsciiSearchResults 
		(
			ID					INT PRIMARY KEY IDENTITY(1,1),
			DatabaseName		SYSNAME NOT NULL,
			SchemaName			SYSNAME NOT NULL,
			TableName			SYSNAME NOT NULL,
			ColumnName			SYSNAME NOT NULL,
			TableRowID			INT	NOT NULL,
			ColumnValue			NVARCHAR(MAX) NOT NULL

		)
	END


	-- Truncate results table before beginning
	TRUNCATE TABLE dbo.AsciiSearchResults

	DECLARE myTables CURSOR READ_ONLY
	FOR 
	SELECT ObjectID, SchemaName, TableName FROM @Objs

	DECLARE @ObjectID INT, @SchemaName SYSNAME, @TableName SYSNAME
	OPEN myTables

	-- Start a loop for all the tables
	FETCH NEXT FROM myTables INTO @ObjectID, @SchemaName, @TableName

	WHILE (@@FETCH_STATUS <> -1)
	BEGIN
		PRINT 'Looping on table: ' + @TableName
		
		-- Start a loop for all the columns in that table
		DECLARE myColumns CURSOR READ_ONLY
		FOR
		SELECT c.name
		FROM sys.schemas s
			INNER JOIN sys.tables t
				ON s.schema_id = t.schema_id
			INNER JOIN sys.columns c
				ON t.object_id = c.object_id
			INNER JOIN sys.types typ
				ON c.system_type_id = typ.system_type_id

		WHERE 
			s.name = 'SEED'
			AND t.name = @TableName
			and typ.system_type_id IN(231) and typ.user_type_id in(231) -- Alphanumeric types only
		ORDER BY c.name

		DECLARE @ColumnName NVARCHAR(MAX), @tsql NVARCHAR(MAX)
		OPEN myColumns

		FETCH NEXT FROM myColumns INTO @ColumnName
		WHILE (@@FETCH_STATUS <> -1)
		BEGIN

			PRINT 'Checking column: ' + @ColumnName + ' on table: ' + @TableName
			SET @tsql = 
			'INSERT INTO dbo.AsciiSearchResults(DatabaseName, SchemaName, TableName, ColumnName, TableRowID, ColumnValue)
			SELECT DB_NAME(), ''SEED'', ''' + @TableName + ''', ''' + @ColumnName + ''', ROWID, ' + @ColumnName + '
			FROM SEED.' + @TableName + '
			WHERE dbo.IsContainsNonAscii (' + @ColumnName + ', ' + CAST(@MinAscii AS VARCHAR(3)) + ', ' + CAST(@MaxAscii AS VARCHAR(3)) + ') = 1
			ORDER BY ' + @ColumnName

			EXEC(@tsql)
			FETCH NEXT FROM myColumns INTO @ColumnName
		END


		-- Clean up columns cursor
		CLOSE myColumns
		DEALLOCATE myColumns

		FETCH NEXT FROM myTables INTO @ObjectID, @SchemaName, @TableName
	END


	-- Clean up tables cursor
	CLOSE myTables
	DEALLOCATE myTables


	-- Return Results
	SELECT * FROM dbo.AsciiSearchResults

GO
