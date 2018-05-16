-- This will compress tables and indexes

SET NOCOUNT ON
-- Generate Table statement
DECLARE @compressionType VARCHAR(10), @MaxLoop INT, @i INT, @SqlStmt VARCHAR(MAX)
SET @compressionType = 'PAGE'

DECLARE @executeMe TABLE
(
	ID INT IDENTITY(1,1) PRIMARY KEY,
	SqlStatement VARCHAR(MAX)
)

INSERT INTO @executeMe
SELECT 'ALTER TABLE ' + QUOTENAME(s.name ) + '.' + QUOTENAME(t.name) + ' REBUILD WITH(DATA_COMPRESSION = ' + @compressionType + ')'
FROM sys.tables t
	INNER JOIN sys.schemas s
		ON t.schema_id = s.schema_id
WHERE s.name = 'X3PERF' AND t.name IN('SORDER', 'SORDERQ', 'SORDERP') 

-- Generate Index statement
INSERT INTO @executeMe
SELECT 'ALTER INDEX ' + QUOTENAME(i.name) + ' ON ' + QUOTENAME(s.name) + '.' + QUOTENAME(i.name) + ' REBUILD WITH(DATA_COMPRESSION = ' + @compressionType + ')'
FROM sys.tables t
	INNER JOIN sys.schemas s
		ON t.schema_id = s.schema_id
	INNER JOIN sys.indexes i
		ON t.object_id = i.object_id
WHERE 
	s.name = 'X3PERF' 
	AND t.name IN('SORDER', 'SORDERQ', 'SORDERP')
	AND i.type <> 0


--SELECT * from @executeMe
SELECT @MaxLoop = COUNT(*) FROM @executeMe

SET @i = 1
WHILE @i <= @MaxLoop
BEGIN
	SELECT @SqlStmt = SqlStatement FROM @executeMe WHERE ID = @i
	PRINT @SqlStmt
	EXEC(@SqlStmt)
	SET @i +=1
END
