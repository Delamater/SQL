WITH cte_tblCnt(SchemaID, TableName, row_count) AS
(
SELECT SCHEMA_NAME(SCHEMA_ID), so.name as TableName, ps.row_count as [RowCount]
FROM sys.objects so
JOIN sys.indexes si
ON si.OBJECT_ID = so.OBJECT_ID
JOIN sys.dm_db_partition_stats AS ps
ON si.OBJECT_ID = ps.OBJECT_ID
AND si.index_id = ps.index_id
WHERE
si.index_id < 2 
	AND so.is_ms_shipped = 0
)
SELECT 
	SchemaID [Schema ID], TableName [Table Name], row_count [Row Count]
FROM cte_tblCnt
ORDER BY SchemaID ASC, row_count DESC