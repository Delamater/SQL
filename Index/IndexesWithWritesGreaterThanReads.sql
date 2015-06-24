-- Potentially inefficent non-clustered indexes (writes > reads)
SELECT  OBJECT_NAME(ddius.[object_id]) AS [Table Name] ,
	i.name AS [Index Name] ,
	i.index_id ,
	user_updates AS [Total Writes] ,
	user_seeks + user_scans + user_lookups AS [Total Reads] ,
	user_updates - ( user_seeks + user_scans + user_lookups )
	AS [Difference]
FROM    sys.dm_db_index_usage_stats AS ddius WITH ( NOLOCK )
	INNER JOIN sys.indexes AS i WITH ( NOLOCK )
	ON ddius.[object_id] = i.[object_id]
	AND i.index_id = ddius.index_id
WHERE   OBJECTPROPERTY(ddius.[object_id], 'IsUserTable') = 1
	AND ddius.database_id = DB_ID()
	AND user_updates > ( user_seeks + user_scans + user_lookups )
	AND i.index_id > 1
ORDER BY [Difference] DESC ,
	[Total Writes] DESC ,
	[Total Reads] ASC ;
