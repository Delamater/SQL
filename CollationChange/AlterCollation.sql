IF OBJECT_ID('uspAlterCollationMethod', 'P') IS NOT NULL
BEGIN
    PRINT 'Recreating function dbo.uspAlterCollationMethod'
    DROP PROCEDURE dbo.uspAlterCollationMethod
END

GO
CREATE PROCEDURE dbo.uspAlterCollationMethod(@NewCollateMethod SYSNAME) AS
BEGIN
	BEGIN TRY
		BEGIN TRAN

		SET NOCOUNT ON

		/********************* Variable Declaration   ****************************/
		DECLARE @SchemaName SYSNAME, @TableName SYSNAME, @ColName SYSNAME, @system_type_name NVARCHAR(256), @Nullable NVARCHAR(25)
		DECLARE @kDropIndexCmd NVARCHAR(25), @kCreateIndexCmd NVARCHAR(25), @kAlterColumnCmd NVARCHAR(25)
		DECLARE @tsql NVARCHAR(MAX), @executionID INT, @commandBuildProgressCount INT, @executionProgressCount INT, @totalCommands INT, @percentComplete DECIMAL(18,6), @statusMsg NVARCHAR(MAX)
		--DECLARE @colInfo TABLE
		--(
		--	ColumnName SYSNAME, system_type_name NVARCHAR(250)
		--)
		DECLARE @X3Users AS dbo.X3Users, @result NVARCHAR(MAX), @dbname SYSNAME
		DECLARE @CommandLog TABLE 
		(
			ID INT PRIMARY KEY IDENTITY(1,1) NOT NULL, 
			Command NVARCHAR(MAX) NOT NULL, 
			CommandType NVARCHAR(25) NOT NULL, 
			ExecutionTime DATETIME
		) 


		SET @kDropIndexCmd		= 'DROP INDEX'
		SET @kCreateIndexCmd	= 'INDEX CREATION'
		SET @kAlterColumnCmd	= 'Collation Change'

		/********************* Sanity Checks *************************************/
		-- Are we an X3 database?
		-- Do we have rights to drop, create and alter objects?



		/********************* Set Up Data To Process ****************************/
		-- Locate tables with collation methods that aren't as desired
		INSERT INTO @X3Users
		SELECT DOSSIER_0 
		FROM X3.ADOSSIER 
		WHERE DOSSIER_0 IN('SEED', 'X3')

		-- Find all the columns needed to process
		-- We must only handle objects in the x3 dictionary, however, a collation conflict can occur for custom tables that exist outside the dictionary. 
		-- Users can collate their queries on the fly with the collate command or transform the objects themselves, 
		-- but we won't transform these custom tables automatically. 
		SELECT * 
		INTO #cols
		--FROM dbo.uspCheckCollationMethod(@X3Users,@NewCollateMethod) 
		FROM dbo.uspGetColumnInfo(@X3Users, '%')  
			--INNER JOIN SEED.ATABLE atb
			--	on c.TableName = QUOTENAME(atb.CODFIC_0 COLLATE Latin1_General_BIN2)		
		WHERE LOWER(collation_name) <> @NewCollateMethod

		-- Create indexes
		CREATE CLUSTERED INDEX clsCols ON #cols(ID)
		CREATE NONCLUSTERED INDEX covCols ON #cols(ID, ColumnName, collation_name, Type, Nullable, SourceTable, SchemaName, TableName)		

		-- Locate computed columns 
		-- Check dependencies 
		-- We will report these changes, but we won't manage them
		-- Forced table validation will remove these 
		-- TODO: Check for entry points that may preserve it

		-- Locate foreign keys 
		-- Check dependencies 
		-- We will report these changes, but we won't manage them
		-- Forced table validation will remove these 
		-- TODO: Check for entry points that may preserve it

		-- Locate primary keys 
		-- Check dependencies 

		-- Locate check constraints
		-- Check dependencies 
		-- If there are, forced table validation should remove it
		-- TODO: Check for entry points that may preserve it


		/********************* Create Drop Index Commands **********************/		
		SELECT SchemaName, TableName
		INTO #distinctTables
		FROM #cols
		GROUP BY SchemaName, TableName
		ORDER BY SchemaName, TableName

		INSERT INTO @CommandLog(Command, CommandType)
		SELECT d.DropSyntax, @kDropIndexCmd 
		FROM #distinctTables t
			CROSS APPLY dbo.uspGetDropIndexesByTableSyntax(SchemaName, TableName) d
		ORDER BY t.SchemaName, t.TableName

		SELECT * FROM @CommandLog -- TODO: REMOVE ME / FOR DEBUG


		/********************* Alter collation methods For objects ***************/	
		/*	
		-- Alter tables and all their columns
		SET @totalCommands = (SELECT COUNT(*) FROM #cols)
		SET @commandBuildProgressCount = 0

		DECLARE commandBuilderCursor CURSOR FORWARD_ONLY FOR 
		--SELECT SchemaName, TableName, ColumnName FROM #cols WHERE SchemaName = 'SEED' AND TableName = 'ABANK'
		--SELECT ColumnName, collation_name, [Type], Nullable, SourceTable, SchemaName, TableName 
		SELECT SchemaName, TableName, ColumnName, [Type]
		FROM #cols
		ORDER BY SchemaName, TableName

		OPEN commandBuilderCursor
		FETCH NEXT FROM commandBuilderCursor INTO @SchemaName, @TableName, @ColName, @system_type_name

		WHILE @@FETCH_STATUS = 0
		BEGIN
			-- Drop index
			--INSERT INTO @CommandLog(Command, CommandType) 
			--SELECT DropSyntax, @kDropIndexCmd FROM dbo.uspGetDropIndexesByTableSyntax(@SchemaName, @TableName)

			-- ALTER TABLE With new Collation
			SET @tsql = CONCAT('ALTER TABLE ', @SchemaName, '.', @TableName, ' ALTER COLUMN ', @ColName, ' ', @system_type_name,' ', 'COLLATE ', @NewCollateMethod)
			INSERT INTO @CommandLog(Command, CommandType) VALUES(@tsql, @kAlterColumnCmd)
			
			-- Add index back
			--INSERT INTO @CommandLog(Command, ExecutionTime)
			--SELECT 
			--	'CREATE ' + 
			--		CASE ORDIND_0 
			--			WHEN 0 THEN 'NONCLUSTERED ' 
			--			WHEN 1 THEN 'CLUSTERED '
			--		END + 

			--	' INDEX ' + CODFIC_0 + '_' + CODIND_0 + ' ON ' + 'SEED' + '.' + CODFIC_0 + '(' + REPLACE(DESCRIPT_0,'+','_0, ') + '_0)' , *
			--FROM SEED.ATABIND ati
			--WHERE CODFIC_0 = 'BANK'

			--INSERT INTO @CommandLog(Command, CommandType)
			--SELECT index_create_statement, @kCreateIndexCmd
			--FROM dbo.uspGetCreateIndexSyntax(@X3Users,@TableName)
			----FROM dbo.uspGetCreateIndexSyntax(@X3Users,'BANK')

			FETCH NEXT FROM commandBuilderCursor INTO @SchemaName, @TableName, @ColName, @system_type_name

			SET @commandBuildProgressCount += 1
			IF @commandBuildProgressCount % 100 = 0
			BEGIN
				SET @statusMsg = 'Command Builder Progress: ' + CAST(@commandBuildProgressCount AS NVARCHAR(20)) + ' columns handled | ' 
									+ @SchemaName + '.' + @TableName + ' ' + @ColName + ' ' + CAST(CURRENT_TIMESTAMP AS NVARCHAR(20))
				RAISERROR(@statusMsg,10,1) WITH NOWAIT
			END
			---- If % complete is a multiple of 10, let's report it
			--SET @percentComplete = 1 - (CAST(@totalCommands AS DECIMAL(18,2)) - CAST(@commandBuildProgressCount AS DECIMAL(18,2))) / CAST(@totalCommands AS DECIMAL(18,2))
			--IF ROUND(@percentComplete,2) % .1 = 0
			--BEGIN
			--	PRINT 'Command Builder Progress: ' + CAST(CAST(ROUND(@percentComplete,2) AS DECIMAL(5,2))AS NVARCHAR(10))
			--END

		END

		CLOSE commandBuilderCursor
		DEALLOCATE commandBuilderCursor
		*/

		INSERT INTO @CommandLog(Command, CommandType) 
		SELECT CONCAT('ALTER TABLE ', c.SchemaName, '.', c.TableName, ' ALTER COLUMN ', c.ColumnName, ' ', c.Type,' ', 'COLLATE ', @NewCollateMethod), @kAlterColumnCmd
		FROM #cols c
		ORDER BY SchemaName, TableName
		SELECT * FROM @CommandLog -- TODO: REMOVE ME / FOR DEBUG
		/********************* Create Index Creation Commands *********************/	
		INSERT INTO @CommandLog(Command, CommandType)
		SELECT d.DropSyntax, @kDropIndexCmd 
		FROM #distinctTables t
			CROSS APPLY dbo.uspGetDropIndexesByTableSyntax(SchemaName, TableName) d
		WHERE t.TableName = 'BANK'

		INSERT INTO @CommandLog(Command, CommandType)
		SELECT index_create_statement, @kCreateIndexCmd
		FROM #distinctTables t
			CROSS APPLY dbo.uspGetCreateIndexSyntax(t.SchemaName, t.TableName) c
		ORDER BY t.SchemaName, t.TableName
		
		SELECT * FROM @CommandLog -- TODO: REMOVE ME / FOR DEBUG


		/************************* Execution Of Commands *************************/
		SET @tsql = ''
		SET @percentComplete  = 0
		SET @totalCommands = 0
		SET @executionProgressCount = 0

		SET @totalCommands = (SELECT COUNT(*) FROM @CommandLog)

		DECLARE executionCursor CURSOR FORWARD_ONLY FOR 
		SELECT Command, ID
		FROM @CommandLog
		ORDER BY ID

		OPEN executionCursor
		FETCH NEXT FROM executionCursor INTO @tsql, @executionID

		WHILE @@FETCH_STATUS = 0
		BEGIN
			EXEC (@tsql)
			UPDATE @CommandLog
			SET ExecutionTime = CURRENT_TIMESTAMP
			WHERE ID = @executionID
			FETCH NEXT FROM executionCursor INTO @tsql, @executionID

			SET @executionProgressCount += 1
			IF @executionProgressCount % 100 = 0
			BEGIN
				SET @statusMsg = 'Execution Progress: ' + CAST(@executionProgressCount AS NVARCHAR(20)) + ' commands executed | ' 
									+ @tsql + ' | ' + CAST(CURRENT_TIMESTAMP AS NVARCHAR(20))
				RAISERROR (@statusMsg, 10, 1) WITH NOWAIT
			END
			--SET @percentComplete = 1 - (CAST(@totalCommands AS DECIMAL(18,2)) - CAST(@executionProgressCount AS DECIMAL(18,2))) / CAST(@totalCommands AS DECIMAL(18,2))
			--IF ROUND(@percentComplete,2) % .1 = 0
			--BEGIN
			--	PRINT 'Execution Progress: ' + CAST(CAST(ROUND(@percentComplete,2) AS DECIMAL(5,2))AS NVARCHAR(10))
			--END
		END

		CLOSE executionCursor
		DEALLOCATE executionCursor
	
		/************************* Recreate the indexes ******************************/
		-- TODO: Custom indexes might be bult with spe routines, this won't work
			-- Recreate the index
		--SET @tsql = (
		--	SELECT 
		--		'CREATE ' + 
		--			CASE ORDIND_0 
		--				WHEN 0 THEN 'NONCLUSTERED ' 
		--				WHEN 1 THEN 'CLUSTERED '
		--			END + 

		--		' INDEX ' + CODFIC_0 + '_' + CODIND_0 + ' ON ' + @SchemaName + '.' + CODFIC_0 + '(' + REPLACE(DESCRIPT_0,'+','_0, ') + '_0)' , *
		--	FROM SEED.ATABIND ati
		--	WHERE CODFIC_0 = 'BANK'
		--)
	

		/************************* Validation Routine ********************************/
		-- Check Foreign Keys

		-- Check  Primary Keys

		-- Check all columns
		SELECT * 
		FROM dbo.uspCheckCollationMethodAggregate(@X3Users, @NewCollateMethod)

		/************************* Drop Objects ********************************/
		DROP TABLE #distinctTables
		DROP TABLE #cols

		/************************* Report Log ********************************/
		SELECT * FROM @CommandLog ORDER BY ID

		COMMIT
	END TRY
	BEGIN CATCH
		-- Report all the commands that were run
		-- In the case of an error, the last command in the queue will may not have executed given the exception, but it will be logged
		SELECT * FROM @CommandLog
		ROLLBACK
		EXECUTE dbo.usp_GetErrorInfo		
	END CATCH

END

GO
