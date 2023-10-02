select * from sys.query_store_plan where query_id = 10626
DECLARE @my_plan_handle varbinary(max)
DECLARE @my_statement_start_offset INT


SELECT 
	@my_plan_handle = qs.plan_handle, @my_statement_start_offset = qs.statement_start_offset
	--*
FROM sys.query_store_plan qsp
	LEFT JOIN sys.dm_exec_query_stats qs
		ON qsp.query_plan_hash = qs.query_plan_hash
WHERE plan_id in (965)


--SELECT 
--	--@my_plan_handle = plan_handle, @my_statement_start_offset = statement_start_offset
--	*
--FROM sys.dm_exec_query_stats where query_plan_hash in 
--	(SELECT query_plan_hash from sys.query_store_plan WHERE plan_id in (965))

select @my_plan_handle, @my_statement_start_offset
--exec sp_create_plan_guide_from_handle @plan_handle = @my_plan_handle, @statement_start_offset = @my_statement_start_offset, @name = 'SomePlanGuide', @hints
--exec dbo.usp_create_plan_guide_with_hint @plan_handle = @my_plan_handle, @statement_start_offset = @my_statement_start_offset, @name=N'MyTestPlanGuide', @hints=NULL
exec dbo.usp_create_plan_guide_with_hint @plan_handle = @my_plan_handle, @statement_start_offset = @my_statement_start_offset, @name=N'MyTestPlanGuide', @hints=N'OPTION (FAST 10000)'


DECLARE @qph varbinary(max)
select @qph = query_plan_hash from sys.query_store_plan  where plan_id = 967
select * from sys.dm_exec_query_stats where query_plan_hash = @qph

select * from 

