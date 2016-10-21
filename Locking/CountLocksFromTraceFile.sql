-- This will count the number of locks by lock type, from a trace table of your choice. Simply alter the trace table designation. 
SELECT 
	t.EventClass, 
	CASE t.Type
		WHEN 1 THEN 'NULL_RESOURCE'
		WHEN 2 THEN 'DATABASE'
		WHEN 3 THEN 'FILE'
		WHEN 5 THEN 'OBJECT'
		WHEN 6 THEN 'PAGE'
		WHEN 7 THEN 'KEY'
		WHEN 8 THEN 'EXTENT'
		WHEN 9 THEN 'RID'
		WHEN 10 THEN 'APPLICATION'
		WHEN 11 THEN 'METADATA'
		WHEN 12 THEN 'HOBT'
		WHEN 13 THEN 'ALLOCATION_UNIT'
		ELSE CAST(t.Type AS VARCHAR(10))
	END AS [Type],
	COUNT(*) CountOfEventAndType, 
	(SELECT e.name FROM sys.trace_events e where e.trace_event_id = t.EventClass) EventType
FROM dbo.[MeasureLocksOnDelivery-NoClusteredIndexes] t
WHERE t.Type IS NOT NULL
GROUP BY t.EventClass, t.Type
