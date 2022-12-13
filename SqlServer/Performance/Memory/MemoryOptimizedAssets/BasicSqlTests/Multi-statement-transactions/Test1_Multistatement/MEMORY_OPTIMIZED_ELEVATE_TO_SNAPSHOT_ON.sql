SET NOCOUNT ON
-- Connection 1
-- Dependency: CreateSampleData2 procedure from script CreateTable.sql
USE TestDB
GO
EXEC dbo.CreateSampleData2 @IsHeap = 1

SELECT NAME, OBJECTPROPERTY(object_id,'TableIsMemoryOptimized') IsMemoryOptimized FROM sys.tables WHERE name IN('SampleData2', 'SampleData_SCHEMA_AND_DATA', 'SampleData_SCHEMA_ONLY')


ALTER DATABASE TestDB SET MEMORY_OPTIMIZED_ELEVATE_TO_SNAPSHOT=ON

BEGIN TRY
	BEGIN TRAN
		-- Step: 1
		UPDATE dbo.SampleData_SCHEMA_AND_DATA -- Memory Optimized
		SET StateID = 'ZZ'
		WHERE ID = 1

		UPDATE dbo.SampleData2 -- Disk Based
		SET StateID = 'ZZ'
		WHERE ID = 2
	--COMMIT
END TRY
BEGIN CATCH
	SELECT ERROR_LINE() ErrorLine, ERROR_MESSAGE() ErrorMessage, ERROR_NUMBER() ErrorNum, ERROR_PROCEDURE() ErrorProcedure, ERROR_SEVERITY() ErrorSeverity, ERROR_STATE() ErrorState
END CATCH

PRINT 'Procedure complete'

ROLLBACK