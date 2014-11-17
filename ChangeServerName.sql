-- Check to see if server names are not equal
IF COALESCE(@@SERVERNAME, '') <>  COALESCE(SERVERPROPERTY('SeverName'), '')
BEGIN
	EXEC sp_dropserver @@SERVERNAME
	EXEC sp_addserver N'<Server Instance Name, VARCHAR(256), ServerName\InstanceName>', local
END


PRINT 'You must restart your SQL Server in order for the changes to be in effect'
