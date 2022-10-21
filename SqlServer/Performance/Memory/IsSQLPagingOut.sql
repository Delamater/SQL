-- Is SQL Server Paging Out?
SELECT 
	(physical_memory_in_use_kb/1024) as Phy_Mem_in_mb,
	(virtual_address_space_committed_kb/1024) as Total_mem_used_MB,
	(virtual_address_space_committed_kb - physical_memory_in_use_kb)/1024 as Mem_as_Pagefile_MB 
 FROM sys.dm_os_process_memory
