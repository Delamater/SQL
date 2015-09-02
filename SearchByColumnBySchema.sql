SELECT s.name Folder, t.name TableName, c.name ColumnName
FROM sys.tables t
	INNER JOIN sys.columns c
		ON t.object_id = c.object_id
	INNER JOIN sys.schemas s
		ON t.schema_id = s.schema_id
WHERE 
	s.name = 'DEMO' 
	AND c.name LIKE '%PID%'
ORDER BY s.name, t.name, c.name
