USE [x3v6]
CREATE TABLE [ECCPROD].[ZBlockedProcessAlerts](
	[ID] [int] NOT NULL,
	[host_process_id] [int] NULL,
	[session_id] [int] NULL,
	[net_packet_size] [int] NULL,
	[net_transport] [nvarchar](80) NULL,
	[local_net_address] [nvarchar](50) NULL,
	[auth_scheme] [nvarchar](80) NULL,
	[client_net_address] [varchar](48) NULL,
	[client_tcp_port] [int] NULL,
	[connect_time] [datetime] NULL,
	[status] [nvarchar](60) NULL,
	[login_name] [nvarchar](128) NULL,
	[database_name] [nvarchar](128) NULL,
	[host_name] [nvarchar](256) NULL,
	[program_name] [nvarchar](256) NULL,
	[blocking_session_id] [int] NULL,
	[command] [nvarchar](64) NULL,
	[reads] [int] NULL,
	[writes] [int] NULL,
	[cpu_time] [int] NULL,
	[wait_type] [nvarchar](120) NULL,
	[wait_time] [int] NULL,
	[last_wait_type] [nvarchar](120) NULL,
	[wait_resource] [nvarchar](512) NULL,
	[transaction_isolation_level] [nvarchar](15) NULL,
	[object_name] [nvarchar](128) NULL,
	[statementText] [nvarchar](max) NULL,
	[statementText2] [nvarchar](max) NULL,
	[OpenTranCount] [int] NULL,
	[IsUserTran] [bit] NULL,
	[EnlistCount] [int] NULL,
	[DbTranBeginTime] [datetime] NULL,
	[DbTranType] [nvarchar](100) NULL,
	[DbTranState] [nvarchar](300) NULL,
	[DbTranLogRecCount] [int] NULL,
	[DbTranLogBytesUsed] [bigint] NULL,
	[TransactionID] [int] NULL,
	[query_plan] [xml] NULL,
	[InsertGUID] [uniqueidentifier] NULL,
	[InsertDate] [datetime] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO


