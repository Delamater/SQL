IF OBJECT_ID('dbo.CachedPlansForScans', 'U') IS NOT NULL
BEGIN
	PRINT 'Recreating table: dbo.CachedPlansForScans'
	DROP TABLE dbo.CachedPlansForScans
END
GO
CREATE TABLE [dbo].[CachedPlansForScans](
	[PlanHandle] [varbinary](64) NOT NULL,
	[ParentOperationID] [int] NULL,
	[OperationID] [int] NULL
) ON [PRIMARY]
SET ANSI_PADDING ON
ALTER TABLE [dbo].[CachedPlansForScans] ADD [PhysicalOperator] [varchar](50) NULL
ALTER TABLE [dbo].[CachedPlansForScans] ADD [LogicalOperator] [varchar](50) NULL
ALTER TABLE [dbo].[CachedPlansForScans] ADD [QueryText] [nvarchar](max) NULL
ALTER TABLE [dbo].[CachedPlansForScans] ADD [CacheObjectType] [nvarchar](50) NOT NULL
ALTER TABLE [dbo].[CachedPlansForScans] ADD [ObjectType] [nvarchar](20) NOT NULL
ALTER TABLE [dbo].[CachedPlansForScans] ADD [EstimatedCost] [float] NULL
ALTER TABLE [dbo].[CachedPlansForScans] ADD [EstimatedIO] [float] NULL
ALTER TABLE [dbo].[CachedPlansForScans] ADD [EstimatedCPU] [float] NULL
ALTER TABLE [dbo].[CachedPlansForScans] ADD [EstimatedRows] [float] NULL
ALTER TABLE [dbo].[CachedPlansForScans] ADD [QueryPlan] [xml] NULL
ALTER TABLE [dbo].[CachedPlansForScans] ADD [ObjectID] [int] NULL


GO
TRUNCATE TABLE dbo.CachedPlansForScans

WITH XMLNAMESPACES
(DEFAULT N'http://schemas.microsoft.com/sqlserver/2004/07/showplan'),
CachedPlans
(
ParentOperationID,
OperationID,
PhysicalOperator,
LogicalOperator,
EstimatedCost,
EstimatedIO,
EstimatedCPU,
EstimatedRows,
PlanHandle,
QueryText,
QueryPlan,
CacheObjectType,
ObjectType,
ObjectID)
AS
(
	SELECT
	RelOp.op.value(N'../../@NodeId', N'int') AS ParentOperationID,
	RelOp.op.value(N'@NodeId', N'int') AS OperationID,
	RelOp.op.value(N'@PhysicalOp', N'varchar(50)') AS PhysicalOperator,
	RelOp.op.value(N'@LogicalOp', N'varchar(50)') AS LogicalOperator,
	RelOp.op.value(N'@EstimatedTotalSubtreeCost ', N'float') AS EstimatedCost,
	RelOp.op.value(N'@EstimateIO', N'float') AS EstimatedIO,
	RelOp.op.value(N'@EstimateCPU', N'float') AS EstimatedCPU,
	RelOp.op.value(N'@EstimateRows', N'float') AS EstimatedRows,
	cp.plan_handle AS PlanHandle,
	st.TEXT AS QueryText,
	qp.query_plan AS QueryPlan,
	cp.cacheobjtype AS CacheObjectType,
	cp.objtype AS ObjectType,
	qp.objectid
	FROM sys.dm_exec_cached_plans cp
	CROSS APPLY sys.dm_exec_sql_text(cp.plan_handle) st
	CROSS APPLY sys.dm_exec_query_plan(cp.plan_handle) qp
	CROSS APPLY qp.query_plan.nodes(N'//RelOp') RelOp (op)
)



INSERT INTO dbo.CachedPlansForScans
SELECT 
PlanHandle,
ParentOperationID,
OperationID,
PhysicalOperator,
LogicalOperator,
QueryText,
CacheObjectType,
ObjectType,
EstimatedCost,
EstimatedIO,
EstimatedCPU,
EstimatedRows,
QueryPlan,
C.ObjectID
--Object_Name(C.ObjectID)
--INTO dbo.CachedPlansForScans
FROM CachedPlans C
Where 
(PhysicalOperator = 'Clustered Index Scan' 
  or 
PhysicalOperator = 'Table Scan' 
 or 
PhysicalOperator = 'Index Scan'
)



select * from dbo.CachedPlansForScans ORDER BY EstimatedRows DESC
