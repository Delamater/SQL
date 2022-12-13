-- Connection 1
-- Dependency: CreateSampleData2 procedure from script CreateTable.sql
USE TestDB
GO
EXEC dbo.CreateSampleData2 @IsHeap = 1

SELECT NAME, OBJECTPROPERTY(object_id,'TableIsMemoryOptimized') IsMemoryOptimized FROM sys.tables WHERE name IN('SampleData2', 'SampleData_SCHEMA_AND_DATA', 'SampleData_SCHEMA_ONLY')

BEGIN TRY
	BEGIN TRAN
		-- Step: 1
		UPDATE dbo.SampleData_SCHEMA_AND_DATA
		SET StateID = 'ZZ'
		WHERE ID = 1

		-- Step: 3
		UPDATE dbo.SampleData_SCHEMA_AND_DATA
		SET StateID = 'ZZ'
		WHERE ID = 2
	--COMMIT
END TRY
BEGIN CATCH
	SELECT ERROR_LINE, ERROR_MESSAGE, ERROR_NUMBER, ERROR_PROCEDURE, ERROR_SEVERITY, ERROR_STATE
END CATCH


ROLLBACK