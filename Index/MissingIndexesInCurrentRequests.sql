SELECT 
	er.session_id,
	er.blocking_session_id,
	er.start_time,
	er.status,
	dbName = DB_NAME(er.database_id),
	er.wait_type,
	er.wait_time,
	er.last_wait_type,
	er.granted_query_memory,
	er.reads,
	er.logical_reads,
	er.writes,
	er.row_count,
	er.total_elapsed_time,
	er.cpu_time,
	er.open_transaction_count,
	er.open_transaction_count,
	s.text,
	qp.query_plan,
	logDate = CONVERT(DATE,GETDATE()),
	logTime = CONVERT(TIME,GETDATE())
FROM sys.dm_exec_requests er 
CROSS APPLY sys.dm_exec_sql_text(er.sql_handle) s
CROSS APPLY sys.dm_exec_query_plan(er.plan_handle) qp
WHERE 
	CONVERT(VARCHAR(MAX), qp.query_plan) LIKE '%<missing%'
