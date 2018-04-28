-- Get sum of max_length of all indexes for a certain table
SELECT 
	s.name, t.name, i.name, 
	--c.name, 
	SUM(c.max_length), COUNT(c.name)
FROM sys.tables t
	INNER JOIN sys.schemas s
		ON t.schema_id = s.schema_id
	INNER JOIN sys.indexes i
		ON i.object_id = t.object_id
	INNER JOIN sys.index_columns ic
		ON i.object_id = ic.object_id
		AND i.index_id = ic.index_id
	INNER JOIN sys.columns c
		ON ic.column_id = c.column_id
		AND ic.object_id = c.object_id
WHERE 
	s.name = 'X3PERF' 
	AND t.name = 'SORDER'
	--AND i.name LIKE 'G%0'
GROUP BY s.name, t.name, i.name
ORDER BY 
	SUM(c.max_length) ASC
	,t.name
	--COUNT(c.name) DESC
