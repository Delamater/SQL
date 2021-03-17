-- The following query lists the permissions explicitly granted or denied ***BY*** server principals
-- See https://docs.microsoft.com/en-us/sql/relational-databases/system-catalog-views/sys-server-permissions-transact-sql?view=sql-server-ver15
SELECT pr.principal_id, pr.name, pr.type_desc,   
    pe.state_desc, pe.permission_name   
FROM sys.server_principals AS pr   
JOIN sys.server_permissions AS pe   
    ON pe.grantor_principal_id = pr.principal_id
WHERE pr.name = '<Server Principle Name, SYSNAME, X3>' OR pr.name = 'sa'
ORDER BY pr.name, pe.permission_name