-- Taken from a trace of refreshing the standard grid on the "Overall Resource Consumption" grid. 
WITH DateGenerator AS
(
SELECT CAST(@interval_start_time AS DATETIME) DatePlaceHolder
UNION ALL
SELECT  DATEADD(hh, 1, DatePlaceHolder)
FROM    DateGenerator
WHERE   DATEADD(hh, 1, DatePlaceHolder) < @interval_end_time
), 
UnionAll AS
(
SELECT
    CONVERT(float, SUM(rs.count_executions)) as total_count_executions,
    ROUND(CONVERT(float, SUM(rs.avg_duration*rs.count_executions))*0.001,2) as total_duration,
    ROUND(CONVERT(float, SUM(rs.avg_cpu_time*rs.count_executions))*0.001,2) as total_cpu_time,
    ROUND(CONVERT(float, SUM(rs.avg_logical_io_reads*rs.count_executions))*8,2) as total_logical_io_reads,
    ROUND(CONVERT(float, SUM(rs.avg_logical_io_writes*rs.count_executions))*8,2) as total_logical_io_writes,
    ROUND(CONVERT(float, SUM(rs.avg_physical_io_reads*rs.count_executions))*8,2) as total_physical_io_reads,
    ROUND(CONVERT(float, SUM(rs.avg_clr_time*rs.count_executions))*0.001,2) as total_clr_time,
    ROUND(CONVERT(float, SUM(rs.avg_dop*rs.count_executions))*1,0) as total_dop,
    ROUND(CONVERT(float, SUM(rs.avg_query_max_used_memory*rs.count_executions))*8,2) as total_query_max_used_memory,
    ROUND(CONVERT(float, SUM(rs.avg_rowcount*rs.count_executions))*1,0) as total_rowcount,
    DATEADD(hh, ((DATEDIFF(hh, 0, rs.last_execution_time))),0 ) as bucket_start,
    DATEADD(hh, (1 + (DATEDIFF(hh, 0, rs.last_execution_time))), 0) as bucket_end
FROM sys.query_store_runtime_stats rs
WHERE NOT (rs.first_execution_time > @interval_end_time OR rs.last_execution_time < @interval_start_time)
GROUP BY DATEDIFF(hh, 0, rs.last_execution_time)
)
SELECT 
    total_count_executions,
    total_duration,
    total_cpu_time,
    total_logical_io_reads,
    total_logical_io_writes,
    total_physical_io_reads,
    total_clr_time,
    total_dop,
    total_query_max_used_memory,
    total_rowcount,
    SWITCHOFFSET(bucket_start, DATEPART(tz, @interval_start_time)) , SWITCHOFFSET(bucket_end, DATEPART(tz, @interval_start_time))
FROM
(
SELECT *, ROW_NUMBER() OVER (PARTITION BY bucket_start ORDER BY bucket_start, total_duration DESC) AS RowNumber
FROM UnionAll 
) as UnionAllResults
WHERE UnionAllResults.RowNumber = 1
OPTION (MAXRECURSION 0)
