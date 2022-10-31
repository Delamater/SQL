SELECT TOP 25
	--sql_text.text,
	OBJECT_NAME(objectid) AS Name,
	SQL_HANDLE,
	plan_generation_num,
	SUBSTRING(TEXT,qs.statement_start_offset/2, 
			(
				CASE 
					WHEN qs.statement_end_offset = -1 
					THEN LEN(CONVERT(NVARCHAR(MAX), TEXT)) * 2 
					ELSE qs.statement_end_offset 
				END - qs.statement_start_offset)/2
			) AS stmt_executing,
	execution_count,
	DBID,
	objectid 
FROM sys.dm_exec_query_stats AS qs
	Cross apply sys.dm_exec_sql_text(sql_handle) sql_text
WHERE 
	plan_generation_num >1
ORDER BY 
	plan_generation_num DESC
