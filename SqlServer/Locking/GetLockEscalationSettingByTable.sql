SELECT 
	s.name SchemaName, 
	t.name TableName, 
	i.name IndexName, 
	i.type_desc IndexType, 
	i.is_unique IndexIsUnique, 
	i.is_primary_key IndexIsPrimaryKey, 
	i.allow_row_locks IndexAllowsRowLocks, 
	i.allow_page_locks IndexAllowsPageLocks, 
	t.lock_escalation_desc TableLockEscalationDesc
FROM sys.tables t
	INNER JOIN sys.schemas s
		ON t.schema_id = s.schema_id
	INNER JOIN sys.indexes i
		ON t.object_id = i.object_id
WHERE 
	t.name IN('STOSER') 
	AND s.name = 'DEMO'
ORDER BY s.name, t.name, i.name
