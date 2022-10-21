
DECLARE @Disable BIT
SET @Disable = 1

SELECT 
	s.name SchemaName, 
	t.name TableName, 
	i.name IndexName, 
	CASE @Disable 
		WHEN 1 THEN 'ALTER INDEX ' + i.name + ' ON ' + QUOTENAME(s.name) + '.' + QUOTENAME(t.name) + ' DISABLE'
		ELSE 'ALTER INDEX ' + i.name + ' ON ' + QUOTENAME(s.name) + '.' + QUOTENAME(t.name) + ' REBUILD' 
	END AS ExecuteMe,
	i.is_disabled,
	i.is_unique,
	i.is_unique_constraint,
	i.type_desc
FROM sys.tables t
	INNER JOIN sys.indexes i
		ON t.object_id = i.object_id
	INNER JOIN sys.schemas s
		ON t.schema_id = s.schema_id
WHERE 
	s.name = 'PILOT1' 
	AND t.name LIKE 'SORDER%'
	AND (i.is_unique <> 1 OR i.is_unique_constraint <> 1)
	AND i.name IS NOT NULL
