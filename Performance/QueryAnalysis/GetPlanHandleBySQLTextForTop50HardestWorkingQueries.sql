-- Find plan handle by SQL text
SELECT 
	OBJECT_NAME(objectid) AS [Name],
	q.[text],
    highest_cpu_queries.plan_handle, 
    highest_cpu_queries.total_worker_time,
    q.dbid,
    q.objectid,
    q.number,
    q.encrypted
FROM 
    (SELECT TOP 50 
        qs.plan_handle, 
        qs.total_worker_time,
		qs.creation_time,
		qs.last_execution_time,
		qs.execution_count,
		qs.Total_Physical_Reads,
		qs.Last_Physical_Reads,
		qs.Min_Physical_Reads,
		qs.Total_Elapsed_Time
    FROM 
        sys.dm_exec_query_stats qs
    ORDER BY qs.total_worker_time DESC) AS highest_cpu_queries
    CROSS APPLY sys.dm_exec_sql_text(plan_handle) AS q
ORDER BY highest_cpu_queries.total_worker_time DESC
