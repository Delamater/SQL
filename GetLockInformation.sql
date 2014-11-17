-- Get locks for session
SELECT 
	l.request_session_id AS SPID,
	es.host_process_id AS HostProcessID,
	DB_NAME(l.resource_database_id) as DatabaseName,
	s.name AS SchemaName,
	o.name AS LockedObjectName,
	p.object_id As LockedObjectID,
	l.resource_type AS LockedResource,
	l.request_mode AS LockType,
	st.text AS SqlStatementText,
	es.login_name AS LoginName,
	es.host_name AS HostName,
	tst.is_user_transaction AS IsUserTransaction,
	at.name AS TransactionName
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
WHERE 
	l.resource_database_id = db_id()
	AND LOWER(l.resource_type) NOT IN('rid', 'key', 'page')
ORDER BY l.request_session_id, l.resource_type

