SELECT  '[' + DB_NAME() + '].[' + su.[name] + '].[' + o.[name] + ']'
	AS [statement] ,
	i.[name] AS [index_name] ,
	ddius.[user_seeks] + ddius.[user_scans] + ddius.[user_lookups]
	AS [user_reads] ,
	ddius.[user_updates] AS [user_writes] ,
	ddios.[leaf_insert_count] ,
	ddios.[leaf_delete_count] ,
	ddios.[leaf_update_count] ,
	ddios.[nonleaf_insert_count] ,
	ddios.[nonleaf_delete_count] ,
	ddios.[nonleaf_update_count]
FROM    sys.dm_db_index_usage_stats ddius
	INNER JOIN sys.indexes i ON ddius.[object_id] = i.[object_id]
		AND i.[index_id] = ddius.[index_id]
	INNER JOIN sys.partitions SP ON ddius.[object_id] = SP.[object_id]
		AND SP.[index_id] = ddius.[index_id]
	INNER JOIN sys.objects o ON ddius.[object_id] = o.[object_id]
	INNER JOIN sys.sysusers su ON o.[schema_id] = su.[UID]
	INNER JOIN sys.[dm_db_index_operational_stats](DB_ID(), NULL, NULL,
	NULL)
	AS ddios
		ON ddius.[index_id] = ddios.[index_id]
		AND ddius.[object_id] = ddios.[object_id]
		AND SP.[partition_number] = ddios.[partition_number]
		AND ddius.[database_id] = ddios.[database_id]
WHERE OBJECTPROPERTY(ddius.[object_id], 'IsUserTable') = 1
	AND ddius.[index_id] > 0
	AND ddius.[user_seeks] + ddius.[user_scans] + ddius.[user_lookups] = 0
ORDER BY ddius.[user_updates] DESC ,
	su.[name] ,
	o.[name] ,
	i.[name]
