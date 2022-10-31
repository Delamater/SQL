SELECT s.name SchemaName, t.name TableName, c.name ColumnName
FROM sys.columns c
	INNER JOIN sys.tables t
		ON t.object_id = c.object_id
	INNER JOIN sys.schemas s
		ON t.schema_id = s.schema_id
WHERE 
	c.name = '<Column Name, SYSNAM, CPY_0>'
	AND s.name = '<Schema Name, SYSNAME, SEED>'
ORDER BY t.name, c.name
