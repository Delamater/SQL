--select * from DLVV11.XAPCKASS
--exec beta_lockinfo 0,0,'F',null

SELECT 
	es.login_time,
	es.host_name,
	es.program_name,
	es.host_process_id,
	es.login_name,
	es.cpu_time,
	es.memory_usage,
	es.total_scheduled_time,
	es.total_elapsed_time,
	ao.name ObjectName,
	dl.resource_type, 
	db_name(dl.resource_database_id) DatabaseName,
	dl.request_mode,
	dl.request_type,
	dl.request_status,
	dl.request_reference_count,
	dl.request_lifetime,
	dl.request_session_id
	--resource_type, resource_associated_entity_id,  
 --   request_status, request_mode,request_session_id,  
 --   resource_description   
FROM sys.dm_tran_locks  dl with(nolock)
	LEFT JOIN sys.all_objects ao with(nolock)
		ON dl.resource_associated_entity_id = ao.object_id
	INNER JOIN sys.dm_exec_sessions es
		ON es.session_id = dl.request_session_id
WHERE 
	--resource_database_id = db_id()
	ao.name IS NOT NULL
ORDER BY db_name(dl.resource_database_id), ao.name
