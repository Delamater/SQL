DECLARE @FailSafeOperator NVARCHAR(255)
EXEC master.dbo.xp_instance_regread
	N'HKEY_LOCAL_MACHINE', N'SOFTWARE\Microsoft\MSSQLServer\SQLServerAgent', N'AlertFailSafeOperator',
	@param = @FailSafeOperator OUT, @no_output = N'no_output'

DECLARE @NotificationMethod int
EXEC master.dbo.xp_instance_regread
	N'HKEY_LOCAL_MACHINE', N'SOFTWARE\Microsoft\MSSQLServer\SQLServerAgent', N'AlertNotificationMethod',
	@param = @NotificationMethod OUT, @no_output = N'no_output'

DECLARE @ForwardingServer NVARCHAR(255)
EXEC master.dbo.xp_instance_regread
	N'HKEY_LOCAL_MACHINE', N'SOFTWARE\Microsoft\MSSQLServer\SQLServerAgent', N'AlertForwardingServer',
	@param = @ForwardingServer OUT, @no_output = N'no_output'

DECLARE @ForwardingSeverity int
EXEC master.dbo.xp_instance_regread
	N'HKEY_LOCAL_MACHINE', N'SOFTWARE\Microsoft\MSSQLServer\SQLServerAgent', N'AlertForwardingSeverity',
	@param = @ForwardingSeverity OUT, @no_output = N'no_output'

DECLARE @ForwardAlways int
EXEC master.dbo.xp_instance_regread
	N'HKEY_LOCAL_MACHINE', N'SOFTWARE\Microsoft\MSSQLServer\SQLServerAgent', N'AlertForwardAlways',
	@param = @ForwardAlways OUT, @no_output = N'no_output'

DECLARE @PagerToTemplate NVARCHAR(255)
EXEC master.dbo.xp_instance_regread
	N'HKEY_LOCAL_MACHINE', N'SOFTWARE\Microsoft\MSSQLServer\SQLServerAgent', N'AlertPagerToTemplate',
	@param = @PagerToTemplate OUT, @no_output = N'no_output'

DECLARE @PagerCCTemplate NVARCHAR(255)
EXEC master.dbo.xp_instance_regread
	N'HKEY_LOCAL_MACHINE', N'SOFTWARE\Microsoft\MSSQLServer\SQLServerAgent', N'AlertPagerCCTemplate',
	@param = @PagerCCTemplate OUT, @no_output = N'no_output'

DECLARE @PagerSubjectTemplate NVARCHAR(255)
EXEC master.dbo.xp_instance_regread
	N'HKEY_LOCAL_MACHINE', N'SOFTWARE\Microsoft\MSSQLServer\SQLServerAgent', N'AlertPagerSubjectTemplate',
	@param = @PagerSubjectTemplate OUT, @no_output = N'no_output'

DECLARE @PagerSendSubjectOnly int
EXEC master.dbo.xp_instance_regread
	N'HKEY_LOCAL_MACHINE', N'SOFTWARE\Microsoft\MSSQLServer\SQLServerAgent', N'AlertPagerSendSubjectOnly',
	@param = @PagerSendSubjectOnly OUT, @no_output = N'no_output'

DECLARE @FailSafeEmailAddress NVARCHAR(255)
EXEC master.dbo.xp_instance_regread
	N'HKEY_LOCAL_MACHINE', N'SOFTWARE\Microsoft\MSSQLServer\SQLServerAgent', N'AlertFailSafeEmailAddress',
	@param = @FailSafeEmailAddress OUT, @no_output = N'no_output'

DECLARE @FailSafePagerAddress NVARCHAR(255)
EXEC master.dbo.xp_instance_regread
	N'HKEY_LOCAL_MACHINE', N'SOFTWARE\Microsoft\MSSQLServer\SQLServerAgent', N'AlertFailSafePagerAddress',
	@param = @FailSafePagerAddress OUT, @no_output = N'no_output'

DECLARE @FailSafeNetSendAddress NVARCHAR(255)
EXEC master.dbo.xp_instance_regread
	N'HKEY_LOCAL_MACHINE', N'SOFTWARE\Microsoft\MSSQLServer\SQLServerAgent', N'AlertFailSafeNetSendAddress',
	@param = @FailSafeNetSendAddress OUT, @no_output = N'no_output'



SELECT
N'AlertSystem' AS [Name],
ISNULL(@FailSafeOperator,N'') AS [FailSafe Operator],
@NotificationMethod AS [Notification Method],
ISNULL(@ForwardingServer,N'') AS [Forwarding Server],
@ForwardingSeverity AS [Forwarding Severity],
CAST(ISNULL(@ForwardAlways, 0) AS bit) AS [Is Forwarded Always],
ISNULL(@PagerToTemplate,N'') AS [Pager To Template],
ISNULL(@PagerCCTemplate,N'') AS [Pager CC Template],
ISNULL(@PagerSubjectTemplate,N'') AS [Pager Subject Template],
CAST(@PagerSendSubjectOnly AS bit) AS [Pager Send Subject Only],
ISNULL(@FailSafeEmailAddress,N'') AS [Fail Safe Email Address],
ISNULL(@FailSafePagerAddress,N'') AS [Fail Safe Pager Address],
ISNULL(@FailSafeNetSendAddress,N'') AS [Fail Safe Net Send Address]
