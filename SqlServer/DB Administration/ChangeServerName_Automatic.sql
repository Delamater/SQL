-- If Computer name is not found in the server name we have to change the server name
IF (SELECT CHARINDEX(CONVERT(VARCHAR(MAX),SERVERPROPERTY('ComputerNamePhysicalNetBIOS')), @@SERVERNAME)) = 0
BEGIN
	PRINT 'Changing SQL Name From: ' + CONVERT(VARCHAR(MAX), SERVERPROPERTY('ComputerNamePhysicalNetBIOS')) + '\' + CONVERT(VARCHAR(MAX),SERVERPROPERTY('InstanceName')) + 'To: ' + CONVERT(VARCHAR(MAX),SERVERPROPERTY('ServerName'))

	DECLARE @NewServerName VARCHAR(MAX)
	SET @NewServerName = CONVERT(VARCHAR(MAX),SERVERPROPERTY('ServerName'))

	EXEC sp_dropserver @@SERVERNAME
	EXEC sp_addserver @NewServerName, local

	PRINT 'Restart SQL Server for the changes to take effect'

END
