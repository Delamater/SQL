IF OBJECT_ID('dbo.CachedPlansForScans', 'U') IS NULL
BEGIN
	PRINT 'Creating table: dbo.CachedPlansForScans'

	CREATE TABLE [dbo].[CachedPlansForScans](
		[PlanHandle] [varbinary](64) NOT NULL,
		[ParentOperationID] [int] NULL,
		[OperationID] [int] NULL,
		[PhysicalOperator] [varchar](50) NULL,
		[LogicalOperator] [varchar](50) NULL,
		[QueryText] [nvarchar](max) NULL,
		[CacheObjectType] [nvarchar](50) NOT NULL,
		[ObjectType] [nvarchar](20) NOT NULL,
		[EstimatedCost] [float] NULL,
		[EstimatedIO] [float] NULL,
		[EstimatedCPU] [float] NULL,
		[EstimatedRows] [float] NULL,
		[QueryPlan] [xml] NULL,
		[ObjectID] [int] NULL,
		[InsertDate] [DATETIME] NOT NULL,
		[BatchID] [UNIQUEIDENTIFIER] NOT NULL
	) 
END
GO



IF OBJECT_ID('dbo.uspGetCachedPlansForScans', 'P') IS NOT NULL
BEGIN
	PRINT 'Recreating procedure dbo.uspGetCachedPlansForScans'
	DROP PROCEDURE dbo.uspGetCachedPlansForScans
END

GO

CREATE PROCEDURE uspGetCachedPlansForScans AS

DECLARE @InsertDate DATETIME, @NewID UNIQUEIDENTIFIER
SET @InsertDate = GETDATE()
SET @NewID = NEWID();


WITH XMLNAMESPACES
(DEFAULT N'http://schemas.microsoft.com/sqlserver/2004/07/showplan'), CachedPlans
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
	ObjectID
)
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
	C.ObjectID,
	@InsertDate,
	@NewID
FROM CachedPlans C
Where 
(
	PhysicalOperator = 'Clustered Index Scan' 
	OR PhysicalOperator = 'Table Scan' 
	OR PhysicalOperator = 'Index Scan'
)

GO
