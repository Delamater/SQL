USE <Databae Name, SYSNAME, x3erpv12>
GO
SELECT sp.name, sp.principal_id, sp.type_desc, sp.default_database_name, dp.default_schema_name, dp.create_date, dp.authentication_type_desc
FROM sys.server_principals sp
	INNER JOIN sys.database_principals dp
		ON sp.sid = dp.sid
ORDER BY sp.name