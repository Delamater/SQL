-- Get total time spent on active triggers 
SELECT 
	DB_NAME(ts.database_id) DatabaseName,
	SCHEMA_NAME(o.schema_id) SchemaName, 
	o.create_date, 
	tr.name TriggerName, 
	tr.type_desc, 
	tr.is_disabled,
	ts.total_logical_reads, 
	ts.total_logical_writes, 
	ts.total_physical_reads,
	ts.total_worker_time / CONVERT(DECIMAL(18,3), 1000000) AS TotalWorkerTime_CPU_Seconds, 
	ts.last_worker_time,
	ts.cached_time
FROM sys.triggers tr
	INNER JOIN sys.all_objects o
		ON tr.object_id = o.object_id
	INNER JOIN sys.dm_exec_trigger_stats ts
		ON tr.object_id = ts.object_id
WHERE is_disabled = 0
ORDER BY ts.total_worker_time DESC
