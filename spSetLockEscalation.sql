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
	CREATE TABLE #LockEscalationChanges
	(
		ID					INT IDENTITY(1,1) NOT NULL,
		SchemaName			SYSNAME NOT NULL,
		TableName			SYSNAME NOT NULL,
		LockEscalationDesc	VARCHAR(MAX) NOT NULL,
		SQLTableToExecute	VARCHAR(MAX) NULL,
		SQLIndexToExecute	VARCHAR(MAX) NULL,
		BatchID				UNIQUEIDENTIFIER NOT NULL,
		RecordDate			DATETIME NOT NULL
		
	)
END

DECLARE @SQLToExecute VARCHAR(MAX), @BatchID UNIQUEIDENTIFIER
SET @BatchID = NEWID()
--SET @RecordDateValue = '''' + CONVERT(VARCHAR(MAX), @RecordDate, 120) + ''''

/****** Discover the indexes to be adjusted to not use lock escalation *****/
SET @SQLToExecute = 
'INSERT INTO #LockEscalationChanges (SchemaName, TableName, LockEscalationDesc, SQLTableToExecute, SQLIndexToExecute, BatchID, RecordDate)
SELECT s.name SchemaName, t.name TableName, t.lock_escalation_desc, NULL, NULL, ''' + CONVERT(VARCHAR(MAX), @BatchID) + ''', GETDATE()
FROM sys.tables t
	INNER JOIN sys.schemas s
		ON t.schema_id = s.schema_id
WHERE 
	t.name IN(' + @DelimittedRangeOfTables + ') 
	AND s.name = ''' + @Schema + '''
ORDER BY t.name'

-- Create stub table records
EXEC(@SQLToExecute)

-- Update the table with the correct SQL to execute
UPDATE #LockEscalationChanges
SET SQLTableToExecute = 
CASE UPPER(@State)
	WHEN 'ON' THEN 'ALTER TABLE ' + @Schema + '.' + TableName + ' SET(LOCK_ESCALATION = TABLE)'
	WHEN 'OFF' THEN 'ALTER TABLE ' + @Schema + '.' + TableName + ' SET(LOCK_ESCALATION = DISABLE)'
	ELSE NULL
END,
SQLIndexToExecute = 'ALTER INDEX ALL ON ' + @Schema + '.' + TableName + ' SET(ALLOW_PAGE_LOCKS = ' + UPPER(@State) + ')'


/**************  Cursor to set all the tables and indexes ***************/
PRINT 'Handling tables' 

DECLARE LockEsc_cur CURSOR FOR
SELECT SQLTableToExecute, SQLIndexToExecute
FROM #LockEscalationChanges

OPEN LockEsc_cur 
FETCH NEXT FROM LockEsc_cur  INTO @TableChangeSQL, @IndexChangeSQL 

WHILE @@FETCH_STATUS = 0
BEGIN
	BEGIN TRY
		IF UPPER(@DiagMode) = 'ON'
			BEGIN
				PRINT @TableChangeSQL
				PRINT @IndexChangeSQL
			END

		IF UPPER(@DiagMode) = 'OFF'
			BEGIN
				EXEC (@TableChangeSQL)
				EXEC (@IndexChangeSQL)
			END
	END TRY
	BEGIN CATCH
		SELECT ERROR_NUMBER() AS ErrorNumber, ERROR_MESSAGE() AS ErrorMessage, @TableSql AS ExecutedSQL
	END CATCH

	FETCH NEXT FROM LockEsc_cur  INTO @TableChangeSQL, @IndexChangeSQL 
END


CLOSE LockEsc_cur
DEALLOCATE LockEsc_cur


-- Report results
SET @SQLToExecute = 
'SELECT 
	s.name SchemaName, 
	t.name TableName, 
	i.name, 
	i.type_desc IndexType, 
	i.is_unique IndexIsUnique, 
	i.is_primary_key IndexIsPrimaryKey, 
	i.allow_row_locks IndexAllowsRowLocks, 
	i.allow_page_locks IndexAllowsPageLocks, 
	t.lock_escalation_desc TableLockEscalationDesc
FROM sys.tables t
	INNER JOIN sys.schemas s
		ON t.schema_id = s.schema_id
	INNER JOIN sys.indexes i
		ON t.object_id = i.object_id
WHERE 
	t.name IN(' + @DelimittedRangeOfTables + ') 
	AND s.name = ''' + @Schema + '''
ORDER BY s.name, t.name, i.name'

EXEC(@SQLToExecute)
GO
--DECLARE @Range VARCHAR(MAX) = '''STOCK'', ''ITMMVT'', ''CPTANALIN'', ''AVALNUM'', ''STOLOTFCY''' 
