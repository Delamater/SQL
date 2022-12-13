SET NOCOUNT ON
-- Connection 1
-- Dependency: CreateSampleData2 procedure from script CreateTable.sql
USE TestDB
GO
EXEC dbo.CreateSampleData2 @IsHeap = 1

SELECT NAME, OBJECTPROPERTY(object_id,'TableIsMemoryOptimized') IsMemoryOptimized FROM sys.tables WHERE name IN('SampleData2', 'SampleData_SCHEMA_AND_DATA', 'SampleData_SCHEMA_ONLY')
SELECT name, state_desc, recovery_model_desc, is_memory_optimized_elevate_to_snapshot_on, snapshot_isolation_state_desc, is_read_committed_snapshot_on from sys.databases WHERE name = 'TestDB'

USE master
GO
ALTER DATABASE TestDB SET MEMORY_OPTIMIZED_ELEVATE_TO_SNAPSHOT=OFF
ALTER DATABASE [TestDB] SET READ_COMMITTED_SNAPSHOT OFF WITH ROLLBACK IMMEDIATE

GO

USE TestDB
GO

BEGIN TRY
	BEGIN TRAN
		-- Step: 1
		UPDATE dbo.SampleData_SCHEMA_AND_DATA -- Memory Optimized
		SET StateID = 'ZZ'
		FROM dbo.SampleData_SCHEMA_AND_DATA	sd 
			INNER JOIN dbo.SampleData_SCHEMA_ONLY s 
				ON (s.ID = sd.ID)
		WHERE s.ID = 1

	SELECT 'UPDATE completed without error' SuccessStatus

	--COMMIT
END TRY
BEGIN CATCH
	SELECT ERROR_LINE() ErrorLine, ERROR_MESSAGE() ErrorMessage, ERROR_NUMBER() ErrorNum, ERROR_PROCEDURE() ErrorProcedure, ERROR_SEVERITY() ErrorSeverity, ERROR_STATE() ErrorState
END CATCH

SELECT * FROM sys.dm_tran_database_transactions WHERE database_id = DB_ID('TestDB')

ROLLBACK

SELECT * FROM sys.dm_tran_database_transactions WHERE database_id = DB_ID('TestDB')
GO
USE master
GO

PRINT 'Procedure complete'