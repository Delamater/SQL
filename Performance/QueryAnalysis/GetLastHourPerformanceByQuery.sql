

-- Get highest aggregate duration queries over last hour (Query 79) (High Aggregate Duration Queries)
WITH AggregatedDurationLastHour
AS
(SELECT q.query_id, SUM(count_executions * avg_duration) AS total_duration,
   COUNT (distinct p.plan_id) AS number_of_plans
   FROM sys.query_store_query_text AS qt WITH (NOLOCK)
   INNER JOIN sys.query_store_query AS q WITH (NOLOCK)
   ON qt.query_text_id = q.query_text_id
   INNER JOIN sys.query_store_plan AS p WITH (NOLOCK)
   ON q.query_id = p.query_id
   INNER JOIN sys.query_store_runtime_stats AS rs WITH (NOLOCK)
   ON rs.plan_id = p.plan_id
   INNER JOIN sys.query_store_runtime_stats_interval AS rsi WITH (NOLOCK)
   ON rsi.runtime_stats_interval_id = rs.runtime_stats_interval_id
   WHERE rsi.start_time >= DATEADD(hour, -1, GETUTCDATE()) 
   AND rs.execution_type_desc = N'Regular'
   GROUP BY q.query_id),
OrderedDuration AS
(SELECT query_id, total_duration, number_of_plans, 
 ROW_NUMBER () OVER (ORDER BY total_duration DESC, query_id) AS RN
 FROM AggregatedDurationLastHour)

SELECT 
	OBJECT_NAME(q.object_id) AS [Containing Object], qt.query_sql_text, 
	od.total_duration AS [Total Duration (microsecs)], 
	od.total_duration / 1000000 AS [Total Duration (secs)], 
	(od.total_duration / 1000000) / 60 AS [Total Duration (mins)], 
	od.number_of_plans AS [Plan Count],
	p.is_forced_plan, p.is_parallel_plan, p.is_trivial_plan,
	q.query_parameterization_type_desc, p.[compatibility_level],
	p.last_compile_start_time, q.last_execution_time,
	CONVERT(xml, p.query_plan) AS query_plan_xml 
FROM OrderedDuration AS od 
	INNER JOIN sys.query_store_query AS q WITH (NOLOCK)
		ON q.query_id  = od.query_id
	INNER JOIN sys.query_store_query_text AS qt WITH (NOLOCK)
		ON q.query_text_id = qt.query_text_id
	INNER JOIN sys.query_store_plan AS p WITH (NOLOCK)
		ON q.query_id = p.query_id
WHERE od.RN <= 50 
ORDER BY total_duration DESC OPTION (RECOMPILE);
