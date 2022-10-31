-- Press Ctrl + Shift + M from within SSMS to replace template parameters
SELECT s.name, t.name, i.name, i.type_desc, c.name, typ.name, typ.max_length, typ.precision, typ.scale, typ.collation_name, c.is_nullable, ic.is_descending_key, ic.is_included_column
FROM sys.indexes i WITH(NOLOCK) 
	inner join sys.index_columns ic
		on i.object_id = ic.object_id
		and i.index_id = ic.index_id
	inner join sys.columns c WITH(NOLOCK) 
		on ic.column_id = c.column_id
		and ic.object_id = c.object_id
	inner join sys.tables t WITH(NOLOCK) 
		on t.object_id = i.object_id
	inner join sys.schemas s WITH(NOLOCK) 
		on t.schema_id = s.schema_id
	inner join sys.types typ WITH(NOLOCK) 
		ON c.system_type_id = typ.system_type_id
		AND c.user_type_id = typ.user_type_id
WHERE 
	s.name = 'SEED'
	AND t.name = 'ITMMASTER'
	AND i.name = 'ITMMASTER_YITM6' OR i.name = 'ITMMASTER_ITM0' OR i.name = 'ITMMASTER_ITM5'
ORDER BY i.name, i.index_id, ic.index_column_id