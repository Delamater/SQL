-- Obtain distinct permission types for the role, regardless of the object
-- See https://docs.microsoft.com/en-us/sql/relational-databases/system-catalog-views/sys-database-principals-transact-sql?view=sql-server-ver15
-- IMPORTANT: The permissions of fixed database roles do not appear in sys.database_permissions. Therefore, database principals may have additional permissions not listed here.
SELECT pr.principal_id, pr.name, pr.type_desc,   
    pr.authentication_type_desc, pe.state_desc, pe.permission_name, COUNT(*) CountOfPermissionType
FROM sys.database_principals AS pr  
JOIN sys.database_permissions AS pe  
    ON pe.grantee_principal_id = pr.principal_id
WHERE pr.name = '<Principal Name, SYSNAME, X3_ADX_SYS>' AND OBJECT_SCHEMA_NAME(pe.major_id) = '<SchemaName, SYSNAME, X3>'
GROUP BY pr.principal_id, pr.name, pr.type_desc, pr.authentication_type_desc, pe.state_desc, pe.permission_name