USE x3v6
GO
-- Checks what locks exist now
SELECT 
	resource_type, 
	DB_NAME(resource_database_id) DbName, 
	OBJECT_NAME(resource_associated_entity_id) TableName, 
	request_mode, request_type, request_session_id
FROM sys.dm_tran_locks 
WHERE 
	resource_type = 'OBJECT' 
	AND resource_database_id = DB_ID() 
	AND resource_associated_entity_id <> 0
ORDER BY TableName



DECLARE 
	@LockType VARCHAR(50), 
	@TablesToLock VARCHAR(MAX),
	@iCtr INT, 
	@sql VARCHAR(MAX),
	@tranName VARCHAR(10)

SET @LockType = 'TABLOCK'
--SET @TablesToLock = 'AVALNUM,AVALATT'


IF (SELECT OBJECT_ID('tempdb..#locks')) IS NULL
BEGIN
	PRINT 'Create #locks'
	CREATE TABLE #locks
	(
		ID				INT	IDENTITY(1,1),
		TableName		SYSNAME,
		SchemaName		SYSNAME,
		ColumnName		SYSNAME,
		Cmd				VARCHAR(MAX)
	)
END

IF @TablesToLock IS NOT NULL
BEGIN
	INSERT INTO #locks(SchemaName, TableName, ColumnName, Cmd)
	SELECT 
		s.name SchemaName, 
		t.name TableName, 
		c.name ColumnName, 
		--typ.name ,
		'SET ROWCOUNT 1; UPDATE ' + s.name + '.' + t.name +  ' WITH(' + @LockType + ') SET ' + c.name + ' = ' + c.name AS ExecuteMe
	FROM sys.schemas s
		INNER JOIN sys.tables t
			on s.schema_id = t.schema_id
		INNER JOIN sys.columns c
			ON t.object_id = c.object_id
	WHERE 
		s.name = 'NATRAINV6'
		AND c.column_id = 1
		--AND t.name IN(@TablesToLock)
		AND CHARINDEX(',' + t.name+ ',', ',' + @TablesToLock + ',') > 0 
END
ELSE
BEGIN
	INSERT INTO #locks(SchemaName, TableName, ColumnName, Cmd)
	SELECT 
		s.name SchemaName, 
		t.name TableName, 
		c.name ColumnName, 
		--typ.name ,
		'SET ROWCOUNT 1; UPDATE ' + s.name + '.' + t.name +  ' WITH(' + @LockType + ') SET ' + c.name + ' = ' + c.name AS ExecuteMe
	FROM sys.schemas s
		INNER JOIN sys.tables t
			on s.schema_id = t.schema_id
		INNER JOIN sys.columns c
			ON t.object_id = c.object_id
	WHERE 
		s.name = 'NATRAINV6'
		AND c.column_id = 1
END
SELECT * FROM #locks 

BEGIN TRAN
SET @iCtr = (SELECT MAX(ID) FROM #locks)

WHILE @iCtr > 0
BEGIN

	SET @sql = (SELECT Cmd FROM #locks WHERE ID = @iCtr) 
	EXEC (@sql)
	SET @iCtr = @iCtr - 1


	--SET @tranName = 'Tran' + CONVERT(VARCHAR(10), @iCtr)
	--SAVE TRAN @tranName
	--SELECT @tranName TranName

END

SELECT 
	resource_type, 
	DB_NAME(resource_database_id) DbName, 
	OBJECT_NAME(resource_associated_entity_id) TableName, 
	request_mode, request_type, request_session_id
FROM sys.dm_tran_locks 
WHERE 
	resource_type = 'OBJECT' 
	AND resource_database_id = DB_ID() 
	AND resource_associated_entity_id <> 0
ORDER BY TableName


--WAITFOR DELAY '00:10:00'
--ROLLBACK TRANSACTION Tran1
DROP TABLE #locks

SELECT @@TRANCOUNT TranCount
