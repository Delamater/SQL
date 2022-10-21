SELECT s.name [Schema_Name], t.name [Table_Name], i.name [Index_Name], COUNT(*) Count_Of_Columns_In_Index
FROM sys.tables t
	INNER JOIN sys.schemas s
		ON t.schema_id = s.schema_id
	INNER JOIN sys.indexes i
		ON i.object_id = t.object_id
	INNER JOIN sys.index_columns ic
		ON i.object_id = ic.object_id
		AND i.index_id = ic.index_id
WHERE 
	s.name = 'X3PERF' 
	--AND t.name = 'SORDER'
GROUP BY s.name, t.name, i.name
ORDER BY COUNT(*) DESC
