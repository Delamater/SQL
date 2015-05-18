-- Count locks by host process id
SELECT es.host_process_id, COUNT(*) CountOfLocksByHostPID
FROM sys.dm_tran_locks l
	INNER JOIN sys.partitions p 
		ON p.hobt_id = l.resource_associated_entity_id
	INNER JOIN sys.objects o
		ON o.object_id = p.object_id
	INNER JOIN sys.dm_exec_sessions es
		ON es.session_id = l.request_session_id
	INNER JOIN sys.dm_tran_session_transactions tst 
		ON es.session_id = tst.session_id
	INNER JOIN sys.dm_tran_active_transactions at
		ON tst.transaction_id = at.transaction_id
	INNER JOIN sys.dm_exec_connections cn
		ON cn.session_id = es.session_id
	LEFT JOIN sys.schemas s
		ON o.schema_id = s.schema_id
	CROSS APPLY sys.dm_exec_sql_text(cn.most_recent_sql_handle) st
WHERE l.resource_database_id = db_id()
GROUP BY es.host_process_id
ORDER BY COUNT(*) DESC
