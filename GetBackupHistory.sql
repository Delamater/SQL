SELECT
	CONVERT(CHAR(100), SERVERPROPERTY('Servername')) AS Server,
	msdb.dbo.backupset.database_name [DB Name],
	msdb.dbo.backupset.backup_start_date [Backup Start Date],
	msdb.dbo.backupset.backup_finish_date [Backup Finish Date],
	msdb.dbo.backupset.expiration_date [Expiration Date],
	CASE msdb..backupset.type
		WHEN 'D' THEN 'Database'
		WHEN 'L' THEN 'Log'
	END AS [Backup Type],
	msdb.dbo.backupset.backup_size [Backup Size],
	msdb.dbo.backupmediafamily.logical_device_name [Logical Device Name],
	msdb.dbo.backupmediafamily.physical_device_name [Physical Device Name],
	msdb.dbo.backupset.name AS [Backupset Name],
	msdb.dbo.backupset.description [Descriptoin]
FROM   msdb.dbo.backupmediafamily
INNER JOIN msdb.dbo.backupset ON msdb.dbo.backupmediafamily.media_set_id = msdb.dbo.backupset.media_set_id
ORDER BY backupset.database_name, backupset.backup_start_date DESC
