SELECT
  GETDATE() -- SnapShotTimeStamp
  --,@SnapshotID -- Snap_Shot_GUID
  ,dmes.session_id -- AS [SESSION_ID]
  ,DB_NAME(dsess.database_id) AS [DATABASE_Name]
  ,dmes.host_name AS [System_Name]
  ,dmes.program_name AS [Program_Name]
  ,dmes.login_name AS [USER_Name]
  ,dmes.host_process_id
  ,dmes.client_interface_name
  ,dmes.status
  ,dmes.cpu_time AS [CPU_TIME_milisec]
  ,dmes.total_scheduled_time AS [Total_Scheduled_TIME_milisec]
  ,dmes.total_elapsed_time AS [Elapsed_TIME_milisec]
  ,(dmes.memory_usage * 8) AS [Memory_USAGE_KB)]
  ,(dsess.user_objects_alloc_page_count * 8) AS [SPACE_Allocated_FOR USER_Objects_KB]
  ,(dsess.user_objects_dealloc_page_count * 8) AS [SPACE_Deallocated_FOR_USER_Objects_KB]
  ,(dsess.internal_objects_alloc_page_count * 8) AS [SPACE_Allocated_FOR_Internal_Objects_KB]
  ,(dsess.internal_objects_dealloc_page_count * 8) AS [SPACE_Deallocated_FOR_Internal_Objects_KB]
  ,CASE dmes.is_user_process
             WHEN 1      THEN 'user session'
             WHEN 0      THEN 'system session'
  END         AS [SESSION Type],
  row_count -- AS [ROW COUNT]
  ,CAST(sqlt.text AS VARCHAR(4000))
FROM sys.dm_db_session_space_usage dsess
      INNER join sys.dm_exec_sessions dmes
            ON  dsess.session_id = dmes.session_id
      LEFT JOIN sys.sysprocesses spn
            ON dmes.session_id = spn.spid
      OUTER APPLY sys.dm_exec_sql_text(spn.sql_handle) sqlt
