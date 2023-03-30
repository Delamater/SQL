SET NOCOUNT ON
DROP TABLE IF EXISTS dbo.ExactTableCount
CREATE TABLE dbo.ExactTableCount(
	SchemaName SYSNAME, 
	TableName SYSNAME,
	MyRowCount BIGINT
)
DECLARE test_cursor CURSOR
READ_ONLY
FOR 
select s.name, t.name, 'INSERT INTO dbo.ExactTableCount (SchemaName, TableName, MyRowCount ) SELECT ''' + s.name + ''', ''' + t.name + ''',  COUNT(*) FROM ' + QUOTENAME(s.name) + '.' + QUOTENAME(t.name)
from sys.schemas s
	inner join sys.tables t
		on s.schema_id = t.schema_id
--where t.name in('ABATPAR', 'ATABLE')

DECLARE @schema_name sysname, @table_name sysname, @count INT, @sql NVARCHAR(MAX)
OPEN test_cursor

FETCH NEXT FROM test_cursor INTO @schema_name, @table_name, @sql
WHILE (@@fetch_status <> -1)
BEGIN
	IF (@@fetch_status <> -2)
	BEGIN
		--PRINT @sql
		EXEC(@sql)
	END
	FETCH NEXT FROM test_cursor INTO @schema_name, @table_name, @sql
END


CLOSE test_cursor
DEALLOCATE test_cursor
GO

SELECT * 
FROM dbo.ExactTableCount
ORDER BY MyRowCount DESC



