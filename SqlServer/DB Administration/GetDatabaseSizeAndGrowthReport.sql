USE master
GO
SELECT 
	d.name DB_Name, 
	a.name Logical_name, 
	a.filename File_Name,
	CAST((a.size * 8.00) / 1024 AS NUMERIC(12,2)) AS DB_Size_in_MB,
		CASE 
			WHEN a.growth > 100 THEN 'In MB' 
			ELSE 'In Percentage' 
		END File_Growth,
	CAST(
		CASE WHEN a.growth > 100 THEN (a.growth * 8.00) / 1024
		ELSE (((a.size * a.growth) / 100) * 8.00) / 1024
	END AS NUMERIC(12,2)) File_Growth_Size_in_MB,
	CASE 
		WHEN ( maxsize = -1 or maxsize=268435456 ) THEN 'AutoGrowth Not Restricted' 
		ELSE 'AutoGrowth Restricted' 
	END AutoGrowth_Status
FROM sysaltfiles a
	join sysdatabases d 
		on a.dbid = d.dbid
WHERE DATABASEPROPERTYEX(d.name, 'status') = 'ONLINE'
ORDER by d.name
