SELECT 
	CASE tl.resource_type
		WHEN 'OBJECT' THEN OBJECT_SCHEMA_NAME(tl.resource_associated_entity_id,db_id()) 
		ELSE CONVERT(NVARCHAR(MAX), tl.resource_associated_entity_id)
	END SchemaName,
	CASE tl.resource_type
		WHEN 'OBJECT' THEN OBJECT_NAME(tl.resource_associated_entity_id) 
		ELSE CONVERT(NVARCHAR(MAX), tl.resource_associated_entity_id)
	END ObjectName,
	tl.resource_type, tl.resource_description, tl.request_mode, tl.request_status, tl.request_reference_count, tl.request_lifetime, tl.request_session_id,
	s.program_name, s.host_name, s.host_process_id, s.status, s.total_elapsed_time, s.last_request_start_time, s.last_request_end_time, s.reads, s.writes, s.logical_reads, s.is_user_process, s.open_transaction_count
FROM sys.dm_tran_locks tl
	LEFT JOIN sys.dm_exec_sessions s
		ON tl.request_session_id = s.session_id
WHERE 
	tl.resource_database_id = db_id()
	AND tl.resource_type <> 'KEY'
	--AND OBJECT_SCHEMA_NAME(tl.resource_associated_entity_id,db_id()) = 'SEED'
	--AND OBJECT_NAME(tl.resource_associated_entity_id) = 'AVALNUM'
	AND tl.resource_associated_entity_id > 0
