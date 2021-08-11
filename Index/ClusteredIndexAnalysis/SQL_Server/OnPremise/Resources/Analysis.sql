USE [clusteredIndexAnalysis]
GO

TRUNCATE TABLE RESEARCH.EMPLOYEE 
TRUNCATE TABLE RESEARCH.EMPLOYEE_NC 
TRUNCATE TABLE RESEARCH.EMPLOYEE_GUID 
TRUNCATE TABLE RESEARCH.EMPLOYEE_GUID_NC 

SELECT
	Database_ID,
	CONVERT(VARCHAR(35),DB_NAME(idx.database_id)) AS [DB Name],
	sch.name [Schema Name],
	idx.[Object_ID],CONVERT(VARCHAR(35),OBJECT_NAME(idx.[OBJECT_ID])) AS 'OBJECT NAME',
	idx.Partition_Number [Partition Number],
	idx.Index_ID [Index ID],
	idx.Index_Type_Desc [Index Type Desc],
	idx.Alloc_Unit_Type_Desc [Alloc Unit Type Desc],
	idx.Index_Depth,Index_Level [Index Depth Level],
	idx.Avg_Fragmentation_In_Percent [Avg Frag Percent],
	idx.Fragment_Count [Frag Count],
	Avg_Fragment_Size_In_Pages [Avg Frag Size In Pages],
	idx.Page_Count [Page Count],
	idx.Avg_Page_Space_Used_In_Percent [Avg Page Space Used In Percent],
	idx.Record_Count [Record Count],
	Ghost_Record_Count [Ghost Record Count],
	idx.Version_Ghost_Record_Count [Version Ghost Record Count],
	idx.Min_Record_Size_In_Bytes [Min Record Size In Bytes],
	idx.Max_Record_Size_In_Bytes [Max Record Size In Bytes],
	idx.Avg_Record_Size_In_Bytes [Avg Record Size In Bytes],
	Forwarded_Record_Count [Forwarded Record Count]
FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'DETAILED') idx
	INNER JOIN sys.tables t
	ON idx.object_id = t.object_id
	INNER JOIN sys.schemas sch
	ON sch.schema_id = t.schema_id
WHERE sch.name = 'RESEARCH' AND t.name IN('EMPLOYEE_GUID_NC', 'EMPLOYEE_GUID')
ORDER BY 
	sch.name, t.name, idx.index_id


UPDATE RESEARCH.EMPLOYEE_GUID_NC
SET ID = NEWID()

UPDATE RESEARCH.EMPLOYEE_GUID
SET ID = NEWID()

SELECT
	Database_ID,
	CONVERT(VARCHAR(35),DB_NAME(idx.database_id)) AS [DB Name],
	sch.name [Schema Name],
	idx.[Object_ID],CONVERT(VARCHAR(35),OBJECT_NAME(idx.[OBJECT_ID])) AS 'OBJECT NAME',
	idx.Partition_Number [Partition Number],
	idx.Index_ID [Index ID],
	idx.Index_Type_Desc [Index Type Desc],
	idx.Alloc_Unit_Type_Desc [Alloc Unit Type Desc],
	idx.Index_Depth,Index_Level [Index Depth Level],
	idx.Avg_Fragmentation_In_Percent [Avg Frag Percent],
	idx.Fragment_Count [Frag Count],
	Avg_Fragment_Size_In_Pages [Avg Frag Size In Pages],
	idx.Page_Count [Page Count],
	idx.Avg_Page_Space_Used_In_Percent [Avg Page Space Used In Percent],
	idx.Record_Count [Record Count],
	Ghost_Record_Count [Ghost Record Count],
	idx.Version_Ghost_Record_Count [Version Ghost Record Count],
	idx.Min_Record_Size_In_Bytes [Min Record Size In Bytes],
	idx.Max_Record_Size_In_Bytes [Max Record Size In Bytes],
	idx.Avg_Record_Size_In_Bytes [Avg Record Size In Bytes],
	Forwarded_Record_Count [Forwarded Record Count]
FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'DETAILED') idx
	INNER JOIN sys.tables t
	ON idx.object_id = t.object_id
	INNER JOIN sys.schemas sch
	ON sch.schema_id = t.schema_id
WHERE sch.name = 'RESEARCH' AND t.name IN('EMPLOYEE_GUID_NC', 'EMPLOYEE_GUID')
--	AND idx.avg_fragmentation_in_percent > 15
--	AND idx.Index_ID > 0
ORDER BY 
	sch.name, t.name, idx.index_id

ALTER INDEX [PK_RESEARCH_EMPLOYEE_GUID_NC] ON [RESEARCH].[EMPLOYEE_GUID_NC] REBUILD 
ALTER INDEX [PK__EMPLOYEE__3214EC27BC682862] ON [RESEARCH].[EMPLOYEE_GUID] REBUILD 
--ALTER TABLE RESEARCH.EMPLOYEE_GUID REBUILD
--ALTER TABLE RESEARCH.EMPLOYEE_GUID_NC REBUILD

UPDATE RESEARCH.EMPLOYEE_GUID_NC
SET ID = NEWID()

UPDATE RESEARCH.EMPLOYEE_GUID
SET ID = NEWID()

SELECT
	Database_ID,
	CONVERT(VARCHAR(35),DB_NAME(idx.database_id)) AS [DB Name],
	sch.name [Schema Name],
	idx.[Object_ID],CONVERT(VARCHAR(35),OBJECT_NAME(idx.[OBJECT_ID])) AS 'OBJECT NAME',
	idx.Partition_Number [Partition Number],
	idx.Index_ID [Index ID],
	idx.Index_Type_Desc [Index Type Desc],
	idx.Alloc_Unit_Type_Desc [Alloc Unit Type Desc],
	idx.Index_Depth,Index_Level [Index Depth Level],
	idx.Avg_Fragmentation_In_Percent [Avg Frag Percent],
	idx.Fragment_Count [Frag Count],
	Avg_Fragment_Size_In_Pages [Avg Frag Size In Pages],
	idx.Page_Count [Page Count],
	idx.Avg_Page_Space_Used_In_Percent [Avg Page Space Used In Percent],
	idx.Record_Count [Record Count],
	Ghost_Record_Count [Ghost Record Count],
	idx.Version_Ghost_Record_Count [Version Ghost Record Count],
	idx.Min_Record_Size_In_Bytes [Min Record Size In Bytes],
	idx.Max_Record_Size_In_Bytes [Max Record Size In Bytes],
	idx.Avg_Record_Size_In_Bytes [Avg Record Size In Bytes],
	Forwarded_Record_Count [Forwarded Record Count]
FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'DETAILED') idx
	INNER JOIN sys.tables t
	ON idx.object_id = t.object_id
	INNER JOIN sys.schemas sch
	ON sch.schema_id = t.schema_id
WHERE sch.name = 'RESEARCH' AND t.name IN('EMPLOYEE_GUID_NC', 'EMPLOYEE_GUID')
ORDER BY 
	sch.name, t.name, idx.index_id

