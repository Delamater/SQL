-- Press Ctrl + Shift + M from within SSMS to replace template parameters
SELECT s.name, t.name, i.name, i.type_desc, ic.*
FROM sys.indexes i
	inner join sys.index_columns ic
		on i.object_id = ic.object_id
		and i.index_id = ic.index_id
	inner join sys.columns c
		on ic.column_id = c.column_id
		and ic.object_id = c.object_id
	inner join sys.tables t
		on t.object_id = i.object_id
	inner join sys.schemas s
		on t.schema_id = s.schema_id
WHERE 
	s.name = '<Schema Name, sysname, SEED>'
	AND t.name = '<Table Name, sysname, ITMMASTER>'
	AND i.name = '<Index Name 1, sysname, ITMMASTER_YITM6>' OR i.name = <Index Name 2, sysname, 'ITMMASTER_ITM0'>
ORDER BY i.name, i.index_id, ic.index_column_id