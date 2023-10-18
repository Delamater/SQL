IF EXISTS (SELECT name FROM sys.server_event_sessions WHERE name = 'Performance_Data_FAST_DEFAULT')
BEGIN
	DROP EVENT SESSION Performance_Data_FAST_DEFAULT ON SERVER
END
GO

CREATE EVENT SESSION [Performance_Data_FAST_DEFAULT] ON SERVER 
ADD EVENT sqlserver.additional_memory_grant(
    ACTION(sqlserver.username)),
ADD EVENT sqlserver.attention(
    ACTION(package0.event_sequence,sqlserver.client_app_name,sqlserver.client_pid,sqlserver.database_id,sqlserver.nt_username,sqlserver.query_hash,sqlserver.server_principal_name,sqlserver.session_id,sqlserver.username)
    WHERE ([package0].[equal_boolean]([sqlserver].[is_system],(0)))),
ADD EVENT sqlserver.background_job_error(
    ACTION(sqlserver.username)),
ADD EVENT sqlserver.batch_hash_table_build_bailout(
    ACTION(sqlserver.username)),
ADD EVENT sqlserver.bitmap_disabled_warning(
    ACTION(sqlserver.username)),
ADD EVENT sqlserver.blocked_process_report(
    ACTION(sqlserver.username)),
ADD EVENT sqlserver.blocked_process_report_filtered(
    ACTION(sqlserver.username)),
ADD EVENT sqlserver.cpu_threshold_exceeded(
    ACTION(sqlserver.username)),
ADD EVENT sqlserver.data_purity_checks_for_dbcompat_130(
    ACTION(sqlserver.username)),
ADD EVENT sqlserver.database_suspect_data_page(
    ACTION(sqlserver.username)),
ADD EVENT sqlserver.error_reported(
    ACTION(sqlserver.username)),
ADD EVENT sqlserver.errorlog_written(
    ACTION(sqlserver.username)),
ADD EVENT sqlserver.exchange_spill(
    ACTION(sqlserver.username)),
ADD EVENT sqlserver.exec_prepared_sql(
    ACTION(sqlserver.username)),
ADD EVENT sqlserver.execution_warning(
    ACTION(sqlserver.username)),
ADD EVENT sqlserver.existing_connection(SET collect_options_text=(1)
    ACTION(package0.event_sequence,sqlserver.client_app_name,sqlserver.client_pid,sqlserver.nt_username,sqlserver.server_principal_name,sqlserver.session_id,sqlserver.username)),
ADD EVENT sqlserver.filestream_file_io_failure(
    ACTION(sqlserver.username)),
ADD EVENT sqlserver.full_update_instead_of_partial_update(
    ACTION(sqlserver.username)),
ADD EVENT sqlserver.fulltextlog_written(
    ACTION(sqlserver.username)),
ADD EVENT sqlserver.hardware_error_rbpex_invalidate_page(
    ACTION(sqlserver.username)),
ADD EVENT sqlserver.hash_spill_details(
    ACTION(sqlserver.username)),
ADD EVENT sqlserver.hash_warning(
    ACTION(sqlserver.username)),
ADD EVENT sqlserver.login(SET collect_options_text=(1)
    ACTION(package0.event_sequence,sqlserver.client_app_name,sqlserver.client_pid,sqlserver.nt_username,sqlserver.server_principal_name,sqlserver.session_id,sqlserver.username)),
ADD EVENT sqlserver.logout(
    ACTION(package0.event_sequence,sqlserver.client_app_name,sqlserver.client_pid,sqlserver.nt_username,sqlserver.server_principal_name,sqlserver.session_id,sqlserver.username)),
ADD EVENT sqlserver.missing_column_statistics(
    ACTION(sqlserver.username)),
ADD EVENT sqlserver.missing_join_predicate(
    ACTION(sqlserver.username)),
ADD EVENT sqlserver.objectname_written(
    ACTION(sqlserver.username)),
ADD EVENT sqlserver.optimizer_timeout(
    ACTION(sqlserver.username)),
ADD EVENT sqlserver.page_covering_rbpex_repair(
    ACTION(sqlserver.username)),
ADD EVENT sqlserver.plan_affecting_convert(
    ACTION(sqlserver.username)),
ADD EVENT sqlserver.plan_guide_successful,
ADD EVENT sqlserver.plan_guide_unsuccessful,
ADD EVENT sqlserver.query_antipattern(
    ACTION(sqlserver.username)),
ADD EVENT sqlserver.query_post_execution_plan_profile(
    ACTION(sqlserver.username)),
ADD EVENT sqlserver.reason_many_foreign_keys_operator_not_used(
    ACTION(sqlserver.username)),
ADD EVENT sqlserver.resourcename_written(
    ACTION(sqlserver.username)),
ADD EVENT sqlserver.rpc_completed(
    ACTION(package0.event_sequence,sqlserver.client_app_name,sqlserver.client_pid,sqlserver.database_id,sqlserver.nt_username,sqlserver.query_hash,sqlserver.server_principal_name,sqlserver.session_id,sqlserver.username)
    WHERE ([package0].[equal_boolean]([sqlserver].[is_system],(0)))),
ADD EVENT sqlserver.session_context_statistics(
    ACTION(sqlserver.username)),
ADD EVENT sqlserver.sort_warning(
    ACTION(sqlserver.username)),
ADD EVENT sqlserver.sp_cache_hit(
    ACTION(sqlserver.username)),
ADD EVENT sqlserver.sp_cache_miss(
    ACTION(sqlserver.username)),
ADD EVENT sqlserver.sp_statement_completed(
    ACTION(sqlserver.username)),
ADD EVENT sqlserver.spatial_guess(
    ACTION(sqlserver.username)),
ADD EVENT sqlserver.sql_batch_completed(
    ACTION(package0.event_sequence,sqlserver.client_app_name,sqlserver.client_pid,sqlserver.database_id,sqlserver.nt_username,sqlserver.query_hash,sqlserver.server_principal_name,sqlserver.session_id,sqlserver.username)
    WHERE ([package0].[equal_boolean]([sqlserver].[is_system],(0)))),
ADD EVENT sqlserver.sql_batch_starting(
    ACTION(package0.event_sequence,sqlserver.client_app_name,sqlserver.client_pid,sqlserver.database_id,sqlserver.nt_username,sqlserver.query_hash,sqlserver.server_principal_name,sqlserver.session_id,sqlserver.username)
    WHERE ([package0].[equal_boolean]([sqlserver].[is_system],(0)))),
ADD EVENT sqlserver.stale_page_foreign_log_redo(
    ACTION(sqlserver.username)),
ADD EVENT sqlserver.stale_page_occurrence(
    ACTION(sqlserver.username)),
ADD EVENT sqlserver.stale_page_rbpex_repair(
    ACTION(sqlserver.username)),
ADD EVENT sqlserver.systemmetadata_written(
    ACTION(sqlserver.username)),
ADD EVENT sqlserver.unmatched_filtered_indexes(
    ACTION(sqlserver.username)),
ADD EVENT xesvlpkg.error_reported(
    ACTION(sqlserver.username))
ADD TARGET package0.event_file(SET filename=N'D:\Sage\X3ERPV12\database\data\PerformanceDataFastDefault')
WITH (MAX_MEMORY=8192 KB,EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,MAX_DISPATCH_LATENCY=5 SECONDS,MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=PER_CPU,TRACK_CAUSALITY=ON,STARTUP_STATE=OFF)
GO


