DECLARE @schema_name SYSNAME = '##SCHEMA_NAME##', @table_name SYSNAME = '##TABLE_NAME##'

SELECT	s.name SchemaName, t.name TableName, c.name ColumnName, typ.name SystemTypeName, c.max_length, c.precision, c.scale, c.is_nullable
FROM sys.tables t
	INNER JOIN sys.schemas s
		ON t.schema_id = s.schema_id
	INNER JOIN sys.columns c
		ON t.object_id = c.object_id
	INNER JOIN sys.types typ
		ON typ.system_type_id = c.system_type_id
		AND typ.user_type_id = c.user_type_id
WHERE s.name = @schema_name AND t.name = @table_name 
ORDER BY s.name, t.name, c.column_id