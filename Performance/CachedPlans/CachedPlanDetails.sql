-- Get all SQL Statements with "table scan" in cached query plan
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
SELECT 
	  RelOp.op.value(N'@PhysicalOp', N'varchar(50)') AS PhysicalOperator
      ,RelOp.op.value(N'@EstimateIO', N'float') AS EstimatedIO
	  ,RelOp.op.value(N'@EstimateCPU', N'float') AS EstimatedCPU
	  ,RelOp.op.value(N'@EstimateRows', N'float') AS EstimatedRows
	  ,RelOp.op.value(N'@Warnings', N'varchar(100)') AS Warnings
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
      ,EQP.[query_plan] AS [QueryPlan]
INTO #wrk
FROM sys.dm_exec_cached_plans AS ECP
     INNER JOIN EQS
         ON ECP.plan_handle = EQS.plan_handle     
     CROSS APPLY sys.dm_exec_sql_text(ECP.[plan_handle]) AS EST
     CROSS APPLY sys.dm_exec_query_plan(ECP.[plan_handle]) AS EQP
	 CROSS APPLY EQP.query_plan.nodes(N'//RelOp') RelOp (op)


-- Performance optimizations
PRINT 'Main query done, now adding indexes for performance'
ALTER TABLE #wrk ADD ID INT IDENTITY(1,1) NOT NULL
CREATE CLUSTERED INDEX clsCachePlans ON #wrk(ID) 
CREATE NONCLUSTERED INDEX idxCachePlans ON #wrk(ID) 
INCLUDE
(
	PhysicalOperator, EstimatedIO, EstimatedCPU, EstimatedRows,
	Warnings, ExecutionCount, TotalWorkTime, TotalLogicalReads, 
	TotalLogicalWrites, TotalElapsedTime, LastExecutionTime, 
	ObjectType, CacheObjectType, DatabaseName, ObjectName, 
	[Statement], QueryPlan
)



SELECT *
FROM #wrk
WHERE 
	PhysicalOperator IN('Table Scan', 'Deleted Scan', 'Index Scan', 'Clustered Index Scan')
	--Statement LIKE '%SELECT TOP 200000%'
ORDER BY EstimatedCPU DESC
--DROP TABLE #wrk

