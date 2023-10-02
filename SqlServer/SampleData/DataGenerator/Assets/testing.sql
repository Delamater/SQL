SELECT s.name SchemaName, t.name TableName, c.name ColumnName, t.name SystemTypeName, c.column_id, c.max_length, c.precision, c.scale, typ.name, ep.*
FROM sys.tables t
	INNER JOIN sys.schemas s
		ON t.schema_id = s.schema_id
	INNER JOIN sys.columns c
		ON t.object_id = c.object_id
	INNER JOIN sys.types typ
		ON c.system_type_id = typ.system_type_id
			AND c.user_type_id = typ.user_type_id
	LEFT OUTER JOIN sys.extended_properties ep
		ON ep.major_id = t.object_id
			AND ep.minor_id = c.column_id 
			AND ep.class = 1
WHERE 
	s.name = 'SEED'
	AND t.name = 'QUREXTRACT'
ORDER BY c.column_id

select * from sys.extended_properties

SELECT objtype, objname, name, value  
FROM fn_listextendedproperty (NULL, 'schema', 'dbo', 'table', 'SampleData', 'column', default);  
GO  


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

WITH cte_sample_data_props AS
(
	SELECT 
		s.name SchemaName, t.name TableName, c.name ColumnName,
		--ep.class, ep.class_desc, ep.major_id, ep.minor_id, ep.name ExtendedPropertyName, ep.value, 
		typ.system_type_id, typ.user_type_id
		
	FROM sys.tables t
		INNER JOIN sys.schemas s
			ON t.schema_id = s.schema_id
		INNER JOIN sys.columns c
			ON t.object_id = c.object_id
		INNER JOIN sys.types typ
			ON c.system_type_id = typ.system_type_id
			AND c.user_type_id = typ.user_type_id
		--LEFT JOIN sys.extended_properties ep
		--	ON ep.major_id = t.object_id 
		--	AND ep.minor_id = c.column_id
		--	AND ep.class = 1
	WHERE 
		t.name = 'SampleData'
		AND s.name = 'dbo'		
)

SELECT * FROM cte_sample_data_props props
select * from dbo.SampleData

SELECT * 
FROM SEED.QUREXTRACT q
	INNER JOIN sys.tables t
		ON t.name = 'QUREXTRACT'
	INNER JOIN sys.schemas s
		ON t.schema_id = s.schema_id
	INNER JOIN sys.columns c
		ON t.object_id = c.object_id
	INNER JOIN cte_sample_data_props props
		ON c.system_type_id = props.system_type_id
		AND c.user_type_id = props.user_type_id

SELECT
   SCHEMA_NAME(tbl.schema_id) AS SchemaName,	
   tbl.name AS TableName, 
   clmns.name AS ColumnName,
   p.name AS ExtendedPropertyName,
   CAST(p.value AS sql_variant) AS ExtendedPropertyValue
FROM
   sys.tables AS tbl
   INNER JOIN sys.all_columns AS clmns ON clmns.object_id=tbl.object_id
   INNER JOIN sys.extended_properties AS p ON p.major_id=tbl.object_id AND p.minor_id=clmns.column_id AND p.class=1
WHERE
   SCHEMA_NAME(tbl.schema_id)='dbo'
   and tbl.name='SampleData' 
   --and clmns.name='sno'
   --and p.name='SNO'