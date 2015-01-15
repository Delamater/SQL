--	Author:		Bob Delamater
--	Date:		01/08/2015
--	Description:	
--		1. Create a new server audit and database audit if it doesn't exist
--
--		2. Locate records where TRUNCATE TABLE was issued for alerting purposes
--		Only find truncate table commands within the last four hours
--		Send a database mail out if a record is found


/**********************************************************************************/
/******************************* Sanity Checks ************************************/
/**********************************************************************************/

-- Is database mail enabled?
IF NOT EXISTS
(
	SELECT name, value_in_use
	FROM sys.configurations
	WHERE LOWER(name) LIKE 'database mail xps' AND value_in_use = 1
)
BEGIN
	PRINT 'Database Mail is not configured. Please configure database mail first, this procedure has been terminated. ' + CHAR(10)
	+ 'See these instructions: http://msdn.microsoft.com/en-us/library/hh245116(v=sql.110).aspx'

	GOTO TERMINATE
END


-- Is database mail started?
IF NOT EXISTS
(
	SELECT * 
	FROM sys.service_queues
	WHERE name = N'ExternalMailQueue' AND is_receive_enabled = 1
)
BEGIN
	PRINT 'Datbase mail is enabled but not started. ' + CHAR(10) 
	+ 'Please correct the database mail configuration and run a test email to ensure it is running correctly'

	GOTO TERMINATE
END

/**********************************************************************************/
/******************************* Audit Creation ***********************************/
/**********************************************************************************/

-- Create server audit
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

-- Enabled the server audit (not enabled by default)
ALTER SERVER AUDIT [Audit-DeleteCommands] WITH (STATE = ON)


-- Create database audit consuming the server audit resource
USE [x3v6]
IF NOT EXISTS(SELECT name FROM sys.database_audit_specifications WHERE name = 'DatabaseAudit-DeleteCommands')
BEGIN
	PRINT 'Creating new database audit specification'
	CREATE DATABASE AUDIT SPECIFICATION [DatabaseAudit-DeleteCommands]
	FOR SERVER AUDIT [Audit-DeleteCommands]
	ADD (DELETE ON DATABASE::[x3v6] BY [DEMO])
	WITH (STATE = ON)
END


/**********************************************************************************/
/************************* Alert: Was TRUNCATE TABLE RUN? *************************/
/**********************************************************************************/
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
		@recipients = 'yourBusinessContinuityTeamEmail@goesHere.com',
		@body = @myBody,
		@body_format = 'HTML',
		@subject = 'ALERT CONDITION: TRUNCATE TABLE COMMAND HAS BEEN RUN - TAKE IMMEDIATE ACTION',
		@from_address = 'SQLServerEmailAccount@yourDomain.com',
		@query = @SQL,
		@attach_query_result_as_file = 1,
		@query_result_width = 32767
END

TERMINATE:
-- End Execution
RETURN