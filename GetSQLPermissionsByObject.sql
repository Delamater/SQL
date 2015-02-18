-- Retrieve Permissions for all objects in a specific database
-- To use the GRANT permissions statement do the following
-- 1. Execute this on a database you trust
-- 2. Retrieve the GRANT insert statement on the table(s) you want
-- 3. Paste it into a new query window against the database /server you want to fix
-- 4. Alter the schema reference to be correct for the new database you are fixing. 
--		Example: 
--			Server 1: GRANT INSERT ON TEST.GRPAUTACE TO X3_ADX
--			Server 2: GRANT INSERT ON PRODUCTION.GRPAUTACE TO X3_ADX
--
--	Note: Press Ctrl + Shift + M to fill in the values for the variables 

SET NOCOUNT ON
USE <Database Name, SYSNAME, x3v7>
GO
SELECT 
	Us.name AS UserName, 
	OBJECT_SCHEMA_NAME(id) SchemaName, 
	Obj.name AS [Object],  
	dp.permission_name AS Permission, 
	'ExecuteMeToGrantPermissions' = 
		'GRANT ' 
		+ dp.permission_name 
		+ ' ON '  
		+ OBJECT_SCHEMA_NAME(id) 
		+ '.' 
		+ Obj.name COLLATE Latin1_General_BIN 
		+ ' TO ' 
		+ Us.name COLLATE Latin1_General_BIN 
FROM sys.database_permissions dp
	JOIN sys.sysusers Us 
		ON dp.grantee_principal_id = Us.uid 
	JOIN sys.sysobjects Obj
		ON dp.major_id = Obj.id 
WHERE Obj.id = OBJECT_ID('<X3 Folder Name, SYSNAME, V6P26>.<Table Name, SYSNAME, TABCOUNTRY>')
ORDER BY SchemaName, Obj.name