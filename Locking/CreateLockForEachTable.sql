USE x3v6
GO
-- Checks what locks exist now
SELECT * FROM sys.dm_tran_locks


DECLARE 
	@LockType VARCHAR(50), 
	@iCtr INT, 
	@sql VARCHAR(MAX)


SET @LockType = 'TABLOCK'

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
SELECT * FROM #locks 
BEGIN TRAN
--DECLARE 	@iCtr INT, @sql VARCHAR(MAX)
SET @iCtr = (SELECT MAX(ID) FROM #locks)
WHILE @iCtr > 0
BEGIN
	SET @sql = (SELECT Cmd FROM #locks WHERE ID = @iCtr) 
	EXEC (@sql)
	SET @iCtr = @iCtr - 1
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

WAITFOR DELAY '00:10:00'
ROLLBACK
DROP TABLE #locks


