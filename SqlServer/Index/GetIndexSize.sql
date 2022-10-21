--DECLARE @X3FolderName SYSNAME
--SET @X3FolderName = 'INSERT YOUR FOLDER NAME HERE'
SELECT
       s.name X3FolderName,
       OBJECT_NAME(i.OBJECT_ID) AS TableName,
       i.name AS IndexName,
       i.index_id AS IndexID,
       8 * SUM(a.used_pages) AS 'Indexsize(KB)'
FROM sys.indexes AS i
       JOIN sys.partitions p 
              ON p.OBJECT_ID = i.OBJECT_ID 
              AND p.index_id = i.index_id
       JOIN sys.allocation_units a 
              ON a.container_id = p.partition_id
       INNER JOIN sys.objects o
              ON i.object_id = o.object_id
       INNER JOIN sys.schemas s
              ON o.schema_id = s.schema_id
--WHERE s.name = @X3FolderName 
GROUP BY s.name, i.OBJECT_ID, i.index_id, i.name
ORDER BY SUM(a.used_pages) DESC
