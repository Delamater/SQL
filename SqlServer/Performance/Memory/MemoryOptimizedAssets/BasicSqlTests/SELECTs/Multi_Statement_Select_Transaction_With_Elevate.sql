SET NOCOUNT ON
-- Connection 1
-- Dependency: CreateSampleData2 procedure from script CreateTable.sql
USE TestDB
GO
EXEC dbo.CreateSampleData2 @IsHeap = 1

SELECT NAME, OBJECTPROPERTY(object_id,'TableIsMemoryOptimized') IsMemoryOptimized FROM sys.tables WHERE name IN('SampleData2', 'SampleData_SCHEMA_AND_DATA', 'SampleData_SCHEMA_ONLY')
SELECT name, state_desc, recovery_model_desc, is_memory_optimized_elevate_to_snapshot_on, snapshot_isolation_state_desc, is_read_committed_snapshot_on from sys.databases WHERE name = 'TestDB'

ALTER DATABASE TestDB SET MEMORY_OPTIMIZED_ELEVATE_TO_SNAPSHOT=ON

BEGIN TRY
	BEGIN TRAN
		-- Step: 1
		SELECT * 
		FROM dbo.SampleData_SCHEMA_AND_DATA WITH (SNAPSHOT) -- Memory Optimized
		WHERE ID = 1

		SELECT * 
		FROM dbo.SampleData_SCHEMA_AND_DATA WITH (SNAPSHOT) -- Memory Optimized
		WHERE ID = 2		
	-- COMMIT
END TRY
BEGIN CATCH
	SELECT ERROR_LINE() ErrorLine, ERROR_MESSAGE() ErrorMessage, ERROR_NUMBER() ErrorNum, ERROR_PROCEDURE() ErrorProcedure, ERROR_SEVERITY() ErrorSeverity, ERROR_STATE() ErrorState
END CATCH

PRINT 'Procedure complete'

ROLLBACK