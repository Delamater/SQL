SELECT  '[' + DB_NAME() + '].[' + OBJECT_SCHEMA_NAME(ddios.[object_id])
	+ '].[' + OBJECT_NAME(ddios.[object_id]) + ']' AS [object_name] ,
	i.[name] AS index_name ,
	ddios.page_io_latch_wait_count ,
	ddios.page_io_latch_wait_in_ms ,
	( ddios.page_io_latch_wait_in_ms / ddios.page_io_latch_wait_count )
	AS avg_page_io_latch_wait_in_ms
FROM    sys.dm_db_index_operational_stats(DB_ID(), NULL, NULL, NULL) ddios
	INNER JOIN sys.indexes i ON ddios.[object_id] = i.[object_id]
	AND i.index_id = ddios.index_id
WHERE   ddios.page_io_latch_wait_count > 0
	AND OBJECTPROPERTY(i.OBJECT_ID, 'IsUserTable') = 1
ORDER BY ddios.page_io_latch_wait_count DESC ,
	avg_page_io_latch_wait_in_ms DESC
