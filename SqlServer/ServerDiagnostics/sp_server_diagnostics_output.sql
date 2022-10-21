SELECT SUBSTRING(CAST(SERVERPROPERTY('ProductVersion') AS VARCHAR(20)),0,3)
IF CAST(CAST(SERVERPROPERTY('ProductVersion') AS VARCHAR(2)) AS SMALLINT) < 11
BEGIN
	PRINT 'This routing is supported with SQL 2012 and higher'
	RETURN
END


IF OBJECT_ID('tempdb..#ServerStats', 'U') IS NOT NULL
BEGIN
	DROP TABLE #ServerStats
END

CREATE TABLE #ServerStats (create_time datetime,
                           component_type sysname,
                           component_name sysname,
                           state int,
                           state_desc sysname,
                           data xml)
INSERT INTO #ServerStats execute sp_server_diagnostics


-- Overview 
SELECT create_time as "Date",
       component_name as "Component",
       state_desc as "Status" 
FROM #ServerStats


-- System
SELECT 'System' AS "System",
       data.value('(/system/@systemCpuUtilization)[1]','bigint') as "System CPU",
       data.value('(/system/@sqlCpuUtilization)[1]','bigint') as "SQL CPU",
       data.value('(/system/@nonYieldingTasksReported)[1]','bigint') as "Non-yielding Tasks",
       data.value('(/system/@pageFaults)[1]','bigint') as "Page Faults",
       data.value('(/system/@latchWarnings)[1]','bigint') as "LatchWarnings"
FROM #ServerStats 
WHERE component_name like 'system'


 -- Memory
SELECT 'Memory' as "Memory",
       data.value('(/resource/memoryReport/entry[@description="Working Set"]/@value)[1]',
          'float')/1024/1024 as "Memory Used by SQL Server (MB)",
       data.value('(/resource/memoryReport/entry[@description="Available Physical Memory"]/@value)[1]',
          'float')/1024/1024 as "Physical Memory Available (MB)",
       data.value('(/resource/@lastNotification)[1]','varchar(100)') 
          as "Last Notification",
       data.value('(/resource/@outOfMemoryExceptions)[1]','bigint') 
          as "Out of Memory Exceptions"
FROM #ServerStats 
WHERE component_name like 'resource'


-- Nonpreemptive waits by duration
SELECT 'Non Preemptive by duration' as "Wait",
       tbl.evt.value('(@waitType)','varchar(100)') as "Wait Type",
       tbl.evt.value('(@waits)','bigint') as "Waits",
       tbl.evt.value('(@averageWaitTime)','bigint') as "Avg Wait Time",
       tbl.evt.value('(@maxWaitTime)','bigint') as "Max Wait Time"
FROM #ServerStats CROSS APPLY 
     data.nodes('/queryProcessing/topWaits/nonPreemptive/byDuration/wait') AS tbl(evt)
WHERE component_name like 'query_processing'

-- Preemptive waits by duration
SELECT 'Preemptive by duration' as "Wait",
       tbl.evt.value('(@waitType)','varchar(100)') as "Wait Type",
       tbl.evt.value('(@waits)','bigint') as "Waits",
       tbl.evt.value('(@averageWaitTime)','bigint') as "Avg Wait Time",
       tbl.evt.value('(@maxWaitTime)','bigint') as "Max Wait Time"
FROM #ServerStats CROSS APPLY
     data.nodes('/queryProcessing/topWaits/preemptive/byDuration/wait') AS tbl(evt)
WHERE component_name like 'query_processing'



-- CPU intensive queries
SELECT 'CPU Intensive Queries' as "CPU Intensive Queries",
    tbl.evt.value('(@sessionId)','bigint') as "Session ID",
    tbl.evt.value('(@command)','varchar(100)') as "Command",
    tbl.evt.value('(@cpuUtilization)','bigint') as "CPU",
    tbl.evt.value('(@cpuTimeMs)','bigint') as "CPU Time (ms)"
FROM #ServerStats CROSS APPLY
    data.nodes('/queryProcessing/cpuIntensiveRequests/request') AS tbl(evt)
WHERE component_name like 'query_processing'


 -- Blocked Process Reports
SELECT 'Blocked Process Report' as "Blocked Process Report",
       tbl.evt.query('.') as "Report XML"
FROM #ServerStats CROSS APPLY
     data.nodes('/queryProcessing/blockingTasks/blocked-process-report') AS tbl(evt)
WHERE component_name like 'query_processing'


 -- IO report
SELECT 'IO Subsystem' as "IO Subsystem",
    data.value('(/ioSubsystem/@ioLatchTimeouts)[1]','bigint') as "Latch Timeouts",
    data.value('(/ioSubsystem/@totalLongIos)[1]','bigint') as "Total Long IOs"
FROM #ServerStats 
WHERE component_name like 'io_subsystem'


-- Event information
SELECT tbl.evt.value('(@name)','varchar(100)') as "Event Name",
    tbl.evt.value('(@package)','varchar(100)') as "Package",
    tbl.evt.value('(@timestamp)','datetime') as "Event Time",
    tbl.evt.query('.') as "Event Data"
FROM #ServerStats 
CROSS APPLY data.nodes('/events/session/RingBufferTarget/event') AS tbl(evt)
WHERE component_name like 'events'
