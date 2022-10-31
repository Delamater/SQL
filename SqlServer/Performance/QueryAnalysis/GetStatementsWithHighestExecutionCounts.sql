/* List Statements with the Highest Execution Counts */
SELECT TOP 50
        OBJECT_NAME(objectid) AS [Name],
		qs.execution_count,
        SUBSTRING(qt.text,qs.statement_start_offset/2, 
			(
				CASE	
					WHEN qs.statement_end_offset = -1 
					THEN LEN(CONVERT(NVARCHAR(MAX), qt.text)) * 2 
					ELSE qs.statement_end_offset END -qs.statement_start_offset)/2
			) AS query_text,
		qt.dbid, 
		dbname=db_name(qt.dbid),
		qt.objectid 
FROM sys.dm_exec_query_stats qs
	CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS qt
ORDER BY 
        qs.execution_count DESC
