;WITH 
 XMLNAMESPACES
    (DEFAULT N'http://schemas.microsoft.com/sqlserver/2004/07/showplan'  
            ,N'http://schemas.microsoft.com/sqlserver/2004/07/showplan' AS ShowPlan) 
,EQS AS
    (SELECT EQS.plan_handle
           ,SUM(EQS.execution_count) AS ExecutionCount
           ,SUM(EQS.total_worker_time) AS TotalWorkTime
           ,SUM(EQS.total_logical_reads) AS TotalLogicalReads
           ,SUM(EQS.total_logical_writes) AS TotalLogicalWrites
           ,SUM(EQS.total_elapsed_time) AS TotalElapsedTime
           ,MAX(EQS.last_execution_time) AS LastExecutionTime
     FROM sys.dm_exec_query_stats AS EQS
     GROUP BY EQS.plan_handle) 
--INSERT INTO dbo.PlanCacheAnalysis  
SELECT 
	  EQS.TotalWorkTime / EQS.ExecutionCount ExecutionEffort
	  ,EQS.[ExecutionCount]
      ,EQS.[TotalWorkTime]
      ,EQS.[TotalLogicalReads]
      ,EQS.[TotalLogicalWrites]
      ,EQS.[TotalElapsedTime]
      ,EQS.[LastExecutionTime]
      ,ECP.[objtype] AS [ObjectType]
      ,ECP.[cacheobjtype] AS [CacheObjectType]
      ,DB_NAME(EST.[dbid]) AS [DatabaseName]
      ,OBJECT_NAME(EST.[objectid], EST.[dbid]) AS [ObjectName]
      ,EST.[text] AS [Statement]      
	  , ECP.plan_handle
      --,EQP.[query_plan] AS [QueryPlan]
FROM sys.dm_exec_cached_plans AS ECP
     INNER JOIN EQS
         ON ECP.plan_handle = EQS.plan_handle     
     CROSS APPLY sys.dm_exec_sql_text(ECP.[plan_handle]) AS EST 
     --CROSS APPLY sys.dm_exec_query_plan(ECP.[plan_handle]) AS EQP
WHERE EQS.[ExecutionCount] > 1  -- No Ad-Hoc queries
      AND ECP.[usecounts] > 1
ORDER BY 
	EQS.TotalWorkTime / EQS.ExecutionCount DESC

SELECT * FROM sys.dm_exec_query_plan(0x060005001CDC4426F046E8200200000001000000000000000000000000000000000000000000000000000000)
