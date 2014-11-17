IF OBJECT_ID('dbo.spSetLockEscalation', 'P') IS NOT NULL
BEGIN
	PRINT 'Recreating dbo.spSetLockEscalation '
	DROP PROCEDURE dbo.spSetLockEscalation 
END
GO

/*
Author:				Bob Delamater
Date:				11/10/2014
Description:		Enables or disables lock escalation and stores the command to a table, 
					along with the values of what the lock escalation values were before hand

Parameters:			@Schema: Name of the schema inside SQL Server to consider. Valid values for this parameter come from sys.schemas.name

					@DelimittedRangeOfTables: You must set a range of tables for the procedure to consider. 
						Example: DECLARE @Range VARCHAR(MAX) = '''STOCK'', ''ITMMVT'', ''CPTANALIN'', ''AVALNUM'', ''STOLOTFCY''' 

					@State:	Valid Values = ON or OFF
						If ON the Table lock escalation will be set to TABLE. 
							AUTO is not considered as it handles partitioning inside SQL, and edge case not handled by this procedure. 
						If OFF then Table lock escalation will be set to OFF

						The default value is OFF. Note, this is different from the default values inside SQL for any given table, 
							so this represents an immediate change

					@DiagMode: Valid valus are ON or OFF
						If On this procedure will not make any changes, but will instead output a list of commands for you 
							to review and execute seperately on your own
						If Off this procedure will execute the changes 

						The default value is OFF

Example Call:		Note: Take care to ensure the table names be case sensitive, should your database be case sensitive
					DECLARE @Range VARCHAR(MAX) = '''STOCK'', ''ITMMVT'', ''CPTANALIN'', ''AVALNUM'', ''STOLOTFCY''' 
					EXEC dbo.spSetLockEscalation @Schema = 'ECCPROD', @DelimittedRangeOfTables = @Range, @State = 'ON', @DiagMode = 'ON'

					
*/
CREATE PROCEDURE dbo.spSetLockEscalation @Schema SYSNAME, @DelimittedRangeOfTables VARCHAR(MAX), @State NVARCHAR(10) = 'OFF', @DiagMode VARCHAR(3) = 'ON'
AS 

-- Set up variables
DECLARE 
	@TableSql VARCHAR(MAX), 
	@TableChangeSQL VARCHAR(MAX),
	@IndexChangeSQL VARCHAR(MAX)

-- Only create the table if it doesn't already exist
IF OBJECT_ID('tempdb..#IndexChanges', 'U') IS NULL
BEGIN
	CREATE TABLE #TableChanges
	(
		ID					INT IDENTITY(1,1) NOT NULL,
		SchemaName			SYSNAME NOT NULL,
		TableName			SYSNAME NOT NULL,
		LockEscalationDesc	VARCHAR(MAX) NOT NULL,
		SQLToExecute		VARCHAR(MAX) NULL,
		BatchID				UNIQUEIDENTIFIER NOT NULL,
		RecordDate			DATETIME NOT NULL
		
	)

	CREATE TABLE #IndexChanges
	(
		ID					INT IDENTITY(1,1) NOT NULL,
		SchemaName			SYSNAME NOT NULL,
		TableName			SYSNAME NOT NULL,
		IndexName			SYSNAME NOT NULL,
		SQLToExecute		VARCHAR(MAX) NOT NULL,
		LockEscalationDesc	VARCHAR(MAX) NOT NULL,
		IsUnique			BIT NULL,
		IsPrimaryKey		BIT NULL,
		AllowRowLocks		BIT NULL,
		AllowPageLocks		BIT NULL,
		BatchID				UNIQUEIDENTIFIER NOT NULL, 
		RecordDate			DATETIME NOT NULL
	)	

END

DECLARE @SQLToExecute VARCHAR(MAX), @BatchID UNIQUEIDENTIFIER
SET @BatchID = NEWID()
--SET @RecordDateValue = '''' + CONVERT(VARCHAR(MAX), @RecordDate, 120) + ''''

/****** Discover the indexes to be adjusted to not use lock escalation *****/
SET @SQLToExecute = 
'INSERT INTO #TableChanges (SchemaName, TableName, LockEscalationDesc, SQLToExecute, BatchID, RecordDate)
SELECT s.name SchemaName, t.name TableName, t.lock_escalation_desc, NULL,  ''' + CONVERT(VARCHAR(MAX), @BatchID) + ''', GETDATE()
FROM sys.tables t
	INNER JOIN sys.schemas s
		ON t.schema_id = s.schema_id
WHERE 
	t.name IN(' + @DelimittedRangeOfTables + ') 
	AND s.name = ''' + @Schema + ''''

-- Create stub table records
EXEC(@SQLToExecute)

-- Update the table with the correct SQL to execute
UPDATE #TableChanges
SET SQLToExecute = 
CASE UPPER(@State)
	WHEN 'ON' THEN 'ALTER TABLE ' + @Schema + '.' + TableName + ' SET(LOCK_ESCALATION = TABLE)'
	WHEN 'OFF' THEN 'ALTER TABLE ' + @Schema + '.' + TableName + ' SET(LOCK_ESCALATION = DISABLE)'
	ELSE NULL
END


/****** Discover the indexes to be adjusted to not use lock escalation *****/
SET @SQLToExecute = 
'INSERT INTO #IndexChanges (SchemaName, TableName, IndexName, SQLToExecute, LockEscalationDesc, IsUnique, IsPrimaryKey, AllowRowLocks, AllowPageLocks, BatchID, RecordDate)
SELECT s.name SchemaName, t.name TableName, i.name IndexName, ''ALTER INDEX '' + i.name + '' ON '' + s.name + ''.'' + t.name +  '' SET(ALLOW_PAGE_LOCKS = ' + UPPER(@State) + ')'' AS SQLToExecute, t.lock_escalation_desc, i.is_unique, i.is_primary_key, i.allow_row_locks, i.allow_page_locks, ''' + CONVERT(VARCHAR(MAX), @BatchID) + ''', GETDATE()
FROM sys.tables t
	INNER JOIN sys.indexes i
		ON t.object_id = i.object_id
	INNER JOIN sys.schemas s
		ON t.schema_id = s.schema_id
WHERE 
	t.name IN(' + @DelimittedRangeOfTables + ')
	AND s.name = ''' + @Schema  + '''
	AND i.name IS NOT NULL 
ORDER BY s.name, t.name, i.name'


-- Create stub records
EXEC(@SQLToExecute)

/**************  Cursor to set all the tables ***************/
PRINT 'Handling tables' 

DECLARE handTables_cur CURSOR FOR
SELECT SQLToExecute
FROM #TableChanges

OPEN handTables_cur 
FETCH NEXT FROM handTables_cur  INTO @TableChangeSQL

WHILE @@FETCH_STATUS = 0
BEGIN
	BEGIN TRY
		IF UPPER(@DiagMode) = 'ON'
			BEGIN
				PRINT @TableChangeSQL
			END

		IF UPPER(@DiagMode) = 'OFF'
			BEGIN
				EXEC (@TableChangeSQL)
			END
	END TRY
	BEGIN CATCH
		SELECT ERROR_NUMBER() AS ErrorNumber, ERROR_MESSAGE() AS ErrorMessage, @TableSql AS ExecutedSQL
	END CATCH

	FETCH NEXT FROM handTables_cur  INTO @TableChangeSQL
END


CLOSE handTables_cur
DEALLOCATE handTables_cur

/**************  Cursor to set all the indexes ***************/
PRINT ' '
PRINT 'Handling indexes' 

DECLARE execTSQLCur CURSOR FOR 
SELECT SQLToExecute
FROM #IndexChanges
WHERE BatchID = @BatchID
	AND IndexName IS NOT NULL

OPEN execTSQLCur 

FETCH NEXT FROM execTSQLCur INTO @IndexChangeSQL  
WHILE @@FETCH_STATUS = 0
BEGIN
	BEGIN TRY
		IF UPPER(@DiagMode) = 'ON'
			BEGIN
				PRINT @IndexChangeSQL  
			END

		IF UPPER(@DiagMode) = 'OFF'
			BEGIN
				EXEC (@IndexChangeSQL)
			END
	END TRY
	BEGIN CATCH
		SELECT ERROR_NUMBER() AS ErrorNumber, ERROR_MESSAGE() AS ErrorMessage
	END CATCH

	FETCH NEXT FROM execTSQLCur INTO @IndexChangeSQL
END

CLOSE execTSQLCur
DEALLOCATE execTSQLCur


GO
--DECLARE @Range VARCHAR(MAX) = '''STOCK'', ''ITMMVT'', ''CPTANALIN'', ''AVALNUM'', ''STOLOTFCY''' 

