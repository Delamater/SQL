-- Script - Find Details for Statistics of Whole Database
-- (c) Pinal Dave
-- Download Script from - https://blog.sqlauthority.com/contact-me/sign-up/
SELECT DISTINCT
OBJECT_NAME(s.[object_id]) AS TableName,
c.name AS ColumnName,
s.name AS StatName,
STATS_DATE(s.[object_id], s.stats_id) AS LastUpdated,
DATEDIFF(d,STATS_DATE(s.[object_id], s.stats_id),getdate()) DaysOld,
dsp.modification_counter,
s.auto_created,
s.user_created,
s.no_recompute,
s.[object_id],
s.stats_id,
sc.stats_column_id,
sc.column_id
FROM sys.stats s
	JOIN sys.stats_columns sc
		ON sc.[object_id] = s.[object_id] AND sc.stats_id = s.stats_id
	JOIN sys.columns c 
		ON c.[object_id] = sc.[object_id] AND c.column_id = sc.column_id
	JOIN sys.partitions par 
		ON par.[object_id] = s.[object_id]
	JOIN sys.objects obj 
		ON par.[object_id] = obj.[object_id]
	CROSS APPLY sys.dm_db_stats_properties(sc.[object_id], s.stats_id) AS dsp
WHERE 
	--OBJECTPROPERTY(s.object_id,'IsUserTable') = 1
	OBJECT_NAME(s.object_id) = 'SampleData'
	--AND (s.auto_created = 1 OR s.user_created = 1)
ORDER BY modification_counter DESC, DaysOld DESC; 
