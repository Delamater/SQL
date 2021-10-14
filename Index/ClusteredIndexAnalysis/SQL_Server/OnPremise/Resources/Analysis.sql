USE [clusteredIndexAnalysis]
GO
-- This is a comment
TRUNCATE TABLE RESEARCH.EMPLOYEE 
TRUNCATE TABLE RESEARCH.EMPLOYEE_NC 
TRUNCATE TABLE RESEARCH.EMPLOYEE_GUID 
TRUNCATE TABLE RESEARCH.EMPLOYEE_GUID_NC 

DECLARE @CurrentPageSplitValue INT
SET @CurrentPageSplitValue = (SELECT cntr_value FROM sys.dm_os_performance_counters WHERE counter_name = 'Page Splits/sec') 

-- Get baseline fragmentation
SELECT @CurrentPageSplitValue PageSplitsReference, RESEARCH.GetPageSplitsDelta(@CurrentPageSplitValue) DeltaPageSplits, * FROM RESEARCH.vGetFrag ORDER BY [Schema Name], [OBJECT NAME], [Index ID], [Alloc Unit Type Desc], [Index Depth Level]

-- Let's fragment some data
UPDATE RESEARCH.EMPLOYEE_GUID_NC SET ID = NEWID()
UPDATE RESEARCH.EMPLOYEE_GUID SET ID = NEWID()

-- Check fragmentation
SELECT @CurrentPageSplitValue PageSplitsReference, RESEARCH.GetPageSplitsDelta(@CurrentPageSplitValue) DeltaPageSplits, * FROM RESEARCH.vGetFrag ORDER BY [Schema Name], [OBJECT NAME], [Index ID], [Alloc Unit Type Desc], [Index Depth Level]
SET @CurrentPageSplitValue = (SELECT cntr_value FROM sys.dm_os_performance_counters WHERE counter_name = 'Page Splits/sec') 

-- Rebuild indexes (NOT REORG)
ALTER INDEX [PK_RESEARCH_EMPLOYEE_GUID_NC] ON [RESEARCH].[EMPLOYEE_GUID_NC] REBUILD 
ALTER INDEX [PK__EMPLOYEE__3214EC27BC682862] ON [RESEARCH].[EMPLOYEE_GUID] REBUILD 

-- Check fragmentation again
SELECT @CurrentPageSplitValue PageSplitsReference, RESEARCH.GetPageSplitsDelta(@CurrentPageSplitValue) DeltaPageSplits, * FROM RESEARCH.vGetFrag ORDER BY [Schema Name], [OBJECT NAME], [Index ID], [Alloc Unit Type Desc], [Index Depth Level]
SET @CurrentPageSplitValue = (SELECT cntr_value FROM sys.dm_os_performance_counters WHERE counter_name = 'Page Splits/sec') 

-- Issue a table rebuild now
ALTER TABLE RESEARCH.EMPLOYEE_GUID REBUILD
ALTER TABLE RESEARCH.EMPLOYEE_GUID_NC REBUILD

-- Did ALTER TABLE REBUILD solve what ALTER INDEX REBUILD couldn't?
SELECT @CurrentPageSplitValue PageSplitsReference, RESEARCH.GetPageSplitsDelta(@CurrentPageSplitValue) DeltaPageSplits, * FROM RESEARCH.vGetFrag ORDER BY [Schema Name], [OBJECT NAME], [Index ID], [Alloc Unit Type Desc], [Index Depth Level]