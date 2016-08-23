SELECT
   @@SERVERNAME AS [ServerName]
   , DB_NAME() AS [DatabaseName]
   , SCHEMA_NAME([sObj].[schema_id]) AS [SchemaName]
   , [sObj].[name] AS [ObjectName]
   , [sObj].type_desc [ObjectType]
   , [sIdx].is_unique IsUnique
   , [ps].row_count
   , [sIdx].[index_id] AS [IndexID]
   , ISNULL([sIdx].[name], 'N/A') AS [IndexName]
   , [sIdx].type_desc
   , [sdmvIUS].[user_seeks] AS [TotalUserSeeks]
   , [sdmvIUS].[user_scans] AS [TotalUserScans]
   , [sdmvIUS].[user_lookups] AS [TotalUserLookups]
   , [sdmvIUS].[user_seeks] + [sdmvIUS].[user_scans] + [sdmvIUS].[user_lookups] TotalUserSeeksScansLookups
   , [sdmvIUS].[user_updates] AS [TotalUserUpdates]
   , [sdmvIUS].[last_user_seek] AS [LastUserSeek]
   , [sdmvIUS].[last_user_scan] AS [LastUserScan]
   , [sdmvIUS].[last_user_lookup] AS [LastUserLookup]
   , [sdmvIUS].[last_user_update] AS [LastUserUpdate]
   , [sdmfIOPS].[leaf_insert_count] AS [LeafLevelInsertCount]
   , [sdmfIOPS].[leaf_update_count] AS [LeafLevelUpdateCount]
   , [sdmfIOPS].[leaf_delete_count] AS [LeafLevelDeleteCount]
FROM
   [sys].[indexes] AS [sIdx]
   INNER JOIN [sys].[objects] AS [sObj]
      ON [sIdx].[object_id] = [sObj].[object_id]
   LEFT JOIN [sys].[dm_db_partition_stats] ps	-- Stats might not exist
	  ON [sIdx].object_id = [ps].object_id
	  AND [sIdx].index_id = ps.index_id
   LEFT JOIN [sys].[dm_db_index_usage_stats] AS [sdmvIUS]
      ON [sIdx].[object_id] = [sdmvIUS].[object_id]
      AND [sIdx].[index_id] = [sdmvIUS].[index_id]
      AND [sdmvIUS].[database_id] = DB_ID()
   LEFT JOIN [sys].[dm_db_index_operational_stats] (DB_ID(),NULL,NULL,NULL) AS [sdmfIOPS]
      ON [sIdx].[object_id] = [sdmfIOPS].[object_id]
      AND [sIdx].[index_id] = [sdmfIOPS].[index_id]
WHERE
   [sObj].[type] IN ('U','V')         -- Look in Tables & Views
   AND [sObj].[is_ms_shipped] = 0x0   -- Exclude System Generated Objects
   AND [sIdx].[is_disabled] = 0x0     -- Exclude Disabled Indexes
ORDER BY [ServerName], [DatabaseName], [SchemaName], [ObjectName], [IndexID]
