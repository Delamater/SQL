WITH RingBuffer AS
(
SELECT CAST(dorb.record AS XML) AS xRecord, dorb.timestamp
FROM sys.dm_os_ring_buffers AS dorb
WHERE dorb.ring_buffer_type = 'RING_BUFFER_RESOURCE_MONITOR'
)

SELECT
xr.value('(ResourceMonitor/Notification)[1]', 'varchar(75)') AS [Rm Notification],
xr.value('(ResourceMonitor/IndicatorsProcess)[1]','tinyint') AS [Indicators Process],
xr.value('(ResourceMonitor/IndicatorsSystem)[1]','tinyint') AS [Indicators System],
DATEADD(ms, -1 * (dosi.ms_ticks/1000) - rb.timestamp, GETDATE()) AS [Rm Date Time],
xr.value('(MemoryNode/TargetMemory)[1]','bigint') AS [Target Memory],
xr.value('(MemoryNode/ReserveMemory)[1]','bigint') AS [Reserve Memory],
xr.value('(MemoryNode/CommittedMemory)[1]','bigint') AS [Commited Memory],
xr.value('(MemoryNode/SharedMemory)[1]','bigint') AS [Shared Memory],
xr.value('(MemoryNode/PagesMemory)[1]','bigint') AS [Pages Memory],
xr.value('(MemoryRecord/MemoryUtilization)[1]','bigint') AS [Memory Utilization],
xr.value('(MemoryRecord/TotalPhysicalMemory)[1]','bigint') AS [Total Physical Memory],
xr.value('(MemoryRecord/AvailablePhysicalMemory)[1]','bigint') AS [Available Physical Memory],
xr.value('(MemoryRecord/TotalPageFile)[1]','bigint') AS [Total Page File],
xr.value('(MemoryRecord/AvailablePageFile)[1]','bigint') AS [Available Page File],
xr.value('(MemoryRecord/TotalVirtualAddressSpace)[1]','bigint') AS [Total Virtual Address Space],
xr.value('(MemoryRecord/AvailableVirtualAddressSpace)[1]','bigint') AS [Available Virtual Address Space],
xr.value('(MemoryRecord/AvailableExtendedVirtualAddressSpace)[1]','bigint') AS [Available Extended Virtual Address Space]
FROM RingBuffer AS rb
CROSS APPLY rb.xRecord.nodes('Record') record (xr)
CROSS JOIN sys.dm_os_sys_info AS dosi
ORDER BY [Rm Date Time]DESC;
