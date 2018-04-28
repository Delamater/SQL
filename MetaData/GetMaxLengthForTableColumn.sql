-- Find max length for columns of a certain schema and table
SELECT s.name SchemaName, t.name TableName, i.name IndexName, c.name ColumnName, typ.name DataTypeName, c.max_length
FROM sys.indexes i
	INNER JOIN sys.index_columns ic
		ON i.object_id = ic.object_id 
		AND i.index_id = ic.index_id
	INNER JOIN sys.tables t
		ON i.object_id = t.object_id
	INNER JOIN sys.schemas s
		ON t.schema_id = s.schema_id
	LEFT JOIN sys.columns c
		ON ic.column_id = c.column_id
		AND ic.object_id = c.object_id
	LEFT JOIN sys.types typ
		ON c.user_type_id = typ.user_type_id
WHERE 
	s.name = 'X3PERF' 
	AND t.name = 'PRJFAS'
--	--AND typ.system_type_id IN(165,173) -- VARBINARY / BINARY
ORDER BY c.max_length DESC
