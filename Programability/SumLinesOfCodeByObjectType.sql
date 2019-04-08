-- Retrieve all the lines of code for this database, grouped by object type
WITH cte AS
(
	SELECT
		DB_NAME(db_id()) DatabaseName,
		OBJECT_SCHEMA_NAME(o.object_id) SchemaName,
		o.type_desc ObjectType,
		LEN(m.definition)- LEN(REPLACE(m.definition,CHAR(10),'')) AS LinesOfCode,
		o.name ObjectName
	FROM sys.all_sql_modules m
		JOIN sys.objects o
		ON m.OBJECT_ID = o.object_id
		-- AND xtype IN('TR', 'P', 'FN', 'IF', 'TF', 'V')
	WHERE OBJECTPROPERTY(o.OBJECT_ID,'IsMSShipped') = 0
)

SELECT DatabaseName, SchemaName, ObjectType, SUM(LinesOfCode)
FROM cte
GROUP BY DatabaseName, SchemaName, ObjectType;
