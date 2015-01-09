--	Author:		Bob Delamater
--	Date:		01/08/2015
--	Description:	
--		1. Create a new server audit and database audit if it doesn't exist
--
--		2. Locate records where TRUNCATE TABLE was issued for alerting purposes
--		Only find truncate table commands within the last four hours
--		Send a database mail out if a record is found

USE [master]
GO
IF NOT EXISTS(SELECT name FROM sys.server_audits WHERE name = 'Audit-DeleteCommands')
BEGIN
	PRINT 'Creating new server audit'

	CREATE SERVER AUDIT [Audit-DeleteCommands]
	TO FILE 
	(	FILEPATH = N'E:\SQLData\'
		,MAXSIZE = 0 MB
		,MAX_ROLLOVER_FILES = 2147483647
		,RESERVE_DISK_SPACE = OFF
	)
	WITH
	(	QUEUE_DELAY = 1000
		,ON_FAILURE = CONTINUE
		,AUDIT_GUID = '37bc19b5-5d19-4998-9000-9e9800b25c70'
	)
END

ALTER SERVER AUDIT [Audit-DeleteCommands] WITH (STATE = ON)

USE [x3v6]
GO

IF NOT EXISTS(SELECT name FROM sys.database_audit_specifications WHERE name = 'DatabaseAudit-DeleteCommands')
BEGIN
	PRINT 'Creating new database audit specification'
	CREATE DATABASE AUDIT SPECIFICATION [DatabaseAudit-DeleteCommands]
	FOR SERVER AUDIT [Audit-DeleteCommands]
	ADD (DELETE ON DATABASE::[x3v6] BY [DEMO])
	WITH (STATE = ON)
END



DEClARE @results	INT,
		@SQL		VARCHAR(MAX)
		


SET @SQL = 
'SELECT 
	a.event_time, 
	DATEDIFF(MINUTE,
		(
			SELECT DATEADD(hh,DATEDIFF(hh,GETUTCDATE(),CURRENT_TIMESTAMP),event_time) -- Compensating for UTC Time
		), 
		GETDATE()) TimeDifferenceInMinutes,
	LTRIM(RTRIM(a.statement)),
	a.action_id, 
	a.succeeded, 
	a.object_name,
	a.server_principal_name, 
	a.database_principal_name, 
	a.server_instance_name, 
	a.database_name, 
	a.schema_name,
	a.file_name
	
FROM sys.fn_get_audit_file(''E:\SQLData\*.sqlaudit'',default,default) a
WHERE 
	LOWER(statement) LIKE ''%truncate%''
	AND 	DATEDIFF(MINUTE,
		(
			SELECT DATEADD(hh,DATEDIFF(hh,GETUTCDATE(),CURRENT_TIMESTAMP),event_time) -- Compensating for UTC Time
		), 
		GETDATE()) <= 240 -- 4hours'

EXEC(@SQL)


SET @results = @@ROWCOUNT

		

IF @results > 0
BEGIN
	DECLARE @myBody VARCHAR(MAX)
	SET @myBody = 'The following TRUNCATE TABLE command was run recently. Please take immediate action to determine root cause. A database restore may, or may not be required depending on the specific table that was truncated.'
	
	
	EXEC msdb.dbo.sp_send_dbmail
		@profile_name = 'ADMIN',
		@recipients = 'bob.delamater@sage.com',
		@body = @myBody,
		@body_format = 'HTML',
		@subject = 'ALERT CONDITION: TRUNCATE TABLE COMMAND HAS BEEN RUN - TAKE IMMEDIATE ACTION',
		@from_address = 'bob.delamater@sage.com',
		@query = @SQL,
		@attach_query_result_as_file = 1,
		@query_result_width = 32767
END
