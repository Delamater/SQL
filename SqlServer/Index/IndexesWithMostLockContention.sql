SELECT  OBJECT_NAME(ddios.OBJECT_ID, ddios.database_id) AS OBJECT_NAME ,
	i.name AS index_name ,
	ddios.index_id ,
	ddios.partition_number ,
	ddios.page_lock_wait_count ,
	ddios.page_lock_wait_in_ms ,
CASE WHEN DDMID.database_id IS NULL THEN 'N'
	ELSE 'Y'
END AS missing_index_identified
FROM    sys.dm_db_index_operational_stats(DB_ID(), NULL, NULL, NULL) ddios
	INNER JOIN sys.indexes i ON ddios.OBJECT_ID = i.OBJECT_ID
AND ddios.index_id = i.index_id
	LEFT OUTER JOIN ( SELECT DISTINCT
		database_id ,
		OBJECT_ID
		FROM      sys.dm_db_missing_index_details
	) AS DDMID ON DDMID.database_id = ddios.database_id
	AND DDMID.OBJECT_ID = ddios.OBJECT_ID
WHERE   ddios.page_lock_wait_in_ms > 0
ORDER BY ddios.page_lock_wait_count DESC
