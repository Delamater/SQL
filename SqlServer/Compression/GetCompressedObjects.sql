-- Which objects are compressed?
SELECT 
s.name
,o.name
,p.[rows] 
,p.[data_compression_desc] 
,i.[index_id] as [IndexID_on_Table]
, i.name
,i.type_desc
,i.is_unique
FROM sys.partitions p
	INNER JOIN sys.objects o
		ON p.object_id = o.object_id 
	INNER JOIN sys.indexes i
		ON o.object_id = i.object_id
	INNER JOIN sys.schemas s
		ON o.schema_id = s.schema_id
WHERE data_compression > 0 
AND s.name <> 'SYS' 
ORDER BY s.name, o.name

