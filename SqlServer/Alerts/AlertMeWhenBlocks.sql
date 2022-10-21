USE x3v6

DECLARE @fullEmailList VARCHAR(MAX), 
		@execSQL VARCHAR(MAX), 
		@InsertGUID UNIQUEIDENTIFIER, 
		@InsertDate DATETIME, 
		@myRowCount INT,
		@myBody VARCHAR(MAX)

SET @fullEmailList = 'bob.delamater@sage.com;pam.nightingale@sage.com'
SET @InsertGUID = NEWID()
SET @InsertDate = GETDATE()

IF OBJECT_ID('ECCPROD.ZBlockedProcessAlerts', 'U') IS NULL
BEGIN
	PRINT 'Creating table ECCPROD.ZBlockedProcessAlerts'
	CREATE TABLE ECCPROD.ZBlockedProcessAlerts
	( 
		ID INT IDENTITY(1,1) PRIMARY KEY, 
		host_process_id INT NULL, 
		session_id INT NULL, 
		net_packet_size INT NULL, 
		net_transport NVARCHAR(80) NULL, 
		local_net_address NVARCHAR(50) NULL, 
		auth_scheme NVARCHAR(80) NULL,
		client_net_address VARCHAR(48) NULL,  
		client_tcp_port INT NULL, 
		connect_time DATETIME NULL, 
		[status] NVARCHAR(60) NULL, 
		login_name SYSNAME NULL, 
		database_name SYSNAME NULL,
		[host_name] NVARCHAR(256) NULL, 
		[program_name] NVARCHAR(256) NULL, 
		blocking_session_id INT NULL, 
		command NVARCHAR(64) NULL, 
		reads INT NULL, 
		writes INT NULL, 
		cpu_time INT NULL,
		wait_type NVARCHAR(120) NULL, 
		wait_time INT NULL, 
		last_wait_type NVARCHAR(120) NULL, 
		wait_resource NVARCHAR(512) NULL, 
		transaction_isolation_level NVARCHAR(15) NULL, 
		[object_name] SYSNAME NULL,
		statementText NVARCHAR(MAX),
		statementText2 NVARCHAR(MAX) NULL, 
		OpenTranCount INT NULL,
		IsUserTran	BIT NULL,
		EnlistCount	INT NULL,
		DbTranBeginTime	DATETIME NULL,
		DbTranType	NVARCHAR(100) NULL,
		DbTranState	NVARCHAR(300) NULL,
		DbTranLogRecCount INT NULL,
		DbTranLogBytesUsed	BIGINT	NULL,
		TransactionID INT NULL,
		query_plan XML NULL, 
		InsertGUID UNIQUEIDENTIFIER NULL, 
		InsertDate DATETIME NULL
	)
END


INSERT INTO ECCPROD.ZBlockedProcessAlerts
( 
	host_process_id, session_id, net_packet_size, net_transport, local_net_address, auth_scheme,
	client_net_address, client_tcp_port, connect_time, [status], login_name, database_name,
	[host_name], [program_name], blocking_session_id, command, reads, writes, cpu_time,
	wait_type, wait_time, last_wait_type, wait_resource, transaction_isolation_level, [object_name],
	statementText, statementText2, OpenTranCount, IsUserTran, EnlistCount, 
	DbTranBeginTime, DbTranType, DbTranState, DbTranLogRecCount, DbTranLogBytesUsed, TransactionID,
	query_plan, InsertGUID, InsertDate
 )
SELECT 
	es.host_process_id
	,es.session_id
	,ec.net_packet_size
	,ec.net_transport
	,ec.local_net_address
	,ec.auth_scheme
	,ec.client_net_address
	,ec.client_tcp_port
	,ec.connect_time
	,es.status
	,es.login_name
	,DB_NAME(er.database_id) 
	,es.host_name
	,es.program_name
	,er.blocking_session_id
	,er.command
	,es.reads
	,es.writes
	,es.cpu_time
	,er.wait_type
	,er.wait_time
	,er.last_wait_type
	,er.wait_resource
	,CASE es.transaction_isolation_level 
		WHEN 0 THEN 'Unspecified'
		WHEN 1 THEN 'ReadUncommitted'
		WHEN 2 THEN 'ReadCommitted'
		WHEN 3 THEN 'Repeatable'
		WHEN 4 THEN 'Serializable'
		WHEN 5 THEN 'Snapshot'
		END AS transaction_isolation_level
	,OBJECT_NAME(st.objectid, er.database_id) ,
	st2.text
	,SUBSTRING(st.text, er.statement_start_offset / 2,
		(CASE WHEN er.statement_end_offset = -1 THEN LEN(CONVERT(nvarchar(max), st.text)) * 2
		ELSE er.statement_end_offset END - er.statement_start_offset) / 2) AS query_text
	,sess.open_transaction_count
	,sess.is_user_transaction
	,sess.enlist_count
	,trans.database_transaction_begin_time
	,CASE trans.database_transaction_type
		WHEN 1 THEN 'Read/Write transaction'
		WhEN 2 THEN 'Read-only transaction'
		WHEN 3 THEN 'System Transaction'
	End
	,CASE trans.database_transaction_state
		WHEN 1 Then 'The transaction has not been initialized'
		WHEN 3 Then 'The transaction has not been initialized but has not generated any log records'
		WhEN 4 THEN 'The transaction has generated log records'
		WHEN 5 THEN 'The transaction has been prepared'
		WHEN 10 THEN 'The transaction has been committed'
		WHEN 11 THEN 'The transaction has been rolled back'
		WHEN 12 THEN 'The transaction is being committed. In this state the log record is being generated, but it has not been materialized or persisted'
	END
	,trans.database_transaction_log_record_count
	,trans.database_transaction_log_bytes_used
	,trans.transaction_id
	,ph.query_plan
	,@InsertGUID 
	,@InsertDate
	FROM sys.dm_exec_connections ec
		LEFT OUTER JOIN sys.dm_exec_sessions es 
			ON ec.session_id = es.session_id
		LEFT OUTER JOIN sys.dm_exec_requests er 
			ON ec.connection_id = er.connection_id
		LEFT JOIN sys.dm_tran_session_transactions sess
			ON sess.session_id = ec.session_id
		LEFT JOIN sys.dm_tran_database_transactions trans
			ON sess.transaction_id = trans.transaction_id
		OUTER APPLY sys.dm_exec_sql_text(sql_handle) st
		OUTER APPLY sys.dm_exec_query_plan(plan_handle) ph
		CROSS APPLY sys.dm_exec_sql_text(ec.most_recent_sql_handle) st2
	--WHERE 
		--ec.session_id <> @@SPID
		--AND es.status = 'running'
		--es.host_process_id = 4636 -- X3 sadoss.exe client process id number
	ORDER BY 
		--es.session_id
		cpu_time DESC

SET @myRowCount = @@ROWCOUNT

IF @myRowCount > 0
BEGIN

	SET @myBody = 'The ECCPROD.ZBlockedProcessAlerts table has been loaded with data. Please run the following query to get these results:'  
	+ CHAR(13) + 'SELECT * FROM x3v6.ECCPROD.ZBlockedProcessAlerts WHERE InsertGUID = ''' + CONVERT(VARCHAR(40), @InsertGUID) + ''''
	USE msdb
	PRINT 'Sending results via DB Mail'
	EXEC msdb.dbo.sp_send_dbmail 
		@profile_name = 'Sage ECC',
		@recipients = @fullEmailList, 
		@body = @myBody,
		@body_format = 'HTML',
		@subject = 'Sage Blocking Alert: ',
		@from_address = 'bob.delamater@Sage.com'

END

