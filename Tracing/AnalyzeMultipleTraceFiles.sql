/**********************************************************************************************
Author:						Bob Delamater
Date:						11/08/2017
Description:				Create a stored procedure that will take a trace table, 
							saved from SQL Profiler to a SQL Server database somewhere, then 
							analyze it according to different techniques, then optionally
							store the analysis in a table for review

Parameters:
	@TblName:				The trace table stored in the database

	@AnalyzeType:			1 = Ordered by reads desc
							2 = Ordered by duration desc

	@StoreIntoTable:		1 = Store the analysis into a final table. This could be useful
							when you want to analyze across multiple traces at once and 
							determine what is causing the most stress over different periods
							of time
	
	@EventTypeFilter:		You can limit the event type to a specific number. 
							For a list of types see sys.trace_events

	@TopFilter:				You may choose to limit the top 10 reads or writes. Set this integer
							to some value to achieve this.


Example call:
EXEC dbo.uspAnalyzeTrace @TblName ='dbo.ADC_lockedprocess_102517', @AnalyzeType = 1, @StoreIntoTable = 1, @EventTypeFilter = NULL, @TopFilter = 25
GO
EXEC dbo.uspAnalyzeTrace @TblName ='dbo.ADC_lockedprocess_102517', @AnalyzeType = 2, @StoreIntoTable = 1, @EventTypeFilter = NULL, @TopFilter = 25
GO
EXEC dbo.uspAnalyzeTrace @TblName ='dbo.1Del_Many_Invoice_102517', @AnalyzeType = 1, @StoreIntoTable = 1, @EventTypeFilter = NULL, @TopFilter = 25
GO
EXEC dbo.uspAnalyzeTrace @TblName ='dbo.1Del_Many_Invoice_102517', @AnalyzeType = 2, @StoreIntoTable = 1, @EventTypeFilter = NULL, @TopFilter = 25


Compilation Instructions: Open this sql file within SQL Server Management Studio and press F5

Compatibility:			SQL 2014. Not tested on previous platforms or newer platforms, 
						but it should work fine. 
				
			
	
***********************************************************************************************/

IF object_id('dbo.uspAnalyzeTrace','P') IS NOT NULL
BEGIN
	PRINT 'Dropping uspAnalyzeTrace'
	DROP PROCEDURE dbo.uspAnalyzeTrace
END
GO
CREATE PROCEDURE dbo.uspAnalyzeTrace @TblName SYSNAME, @AnalyzeType SMALLINT, @StoreIntoTable BIT, @EventTypeFilter INT, @TopFilter INT AS
BEGIN

	/* Declare variables */
	DECLARE @sql VARCHAR(MAX), @SelectList VARCHAR(MAX), @Predicate VARCHAR(MAX), @OrderBy VARCHAR(MAX)

	--drop table dbo.StoredTraces
	/* Create table if doesn't exist */
	IF object_id('dbo.StoredTraces','U') IS NULL
	BEGIN
		PRINT 'Creating [StoredTraces]'
		CREATE TABLE [dbo].[StoredTraces](
			--[RowNumber] [int] IDENTITY(0,1) NOT NULL,
			TraceTableName SYSNAME,
			AnalyzeType NVARCHAR(MAX) NULL,
			EventName NVARCHAR(MAX) NOT NULL,
			DurationInSeconds INT  NULL,
			[RowNumber] [int] NOT NULL,
			[EventClass] [int] NULL,
			[TextData] [ntext] NULL,
			[ApplicationName] [nvarchar](128) NULL,
			[NTUserName] [nvarchar](128) NULL,
			[LoginName] [nvarchar](128) NULL,
			[CPU] [int] NULL,
			[Reads] [bigint] NULL,
			[Writes] [bigint] NULL,
			[Duration] [bigint] NULL,
			[ClientProcessID] [int] NULL,
			[SPID] [int] NULL,
			[StartTime] [datetime] NULL,
			[EndTime] [datetime] NULL,
			[BinaryData] [image] NULL,
			[DatabaseID] [int] NULL,
			[EventSequence] [bigint] NULL,
			[IndexID] [int] NULL,
			[IsSystem] [int] NULL,
			[LoginSid] [image] NULL,
			[Mode] [int] NULL,
			[ObjectID] [int] NULL,
			[ServerName] [nvarchar](128) NULL,
			[SessionLoginName] [nvarchar](128) NULL,
			[TransactionID] [bigint] NULL,
			[DatabaseName] [nvarchar](128) NULL,
			[Error] [int] NULL,
			[HostName] [nvarchar](128) NULL,
			[NTDomainName] [nvarchar](128) NULL,
			[RequestID] [int] NULL,
			[Severity] [int] NULL,
			[State] [int] NULL,
			[GroupID] [int] NULL,
			[XactSequence] [bigint] NULL,
			[EventSubClass] [int] NULL,
			[LineNumber] [int] NULL,
			[NestLevel] [int] NULL,
			[ObjectName] [nvarchar](128) NULL,
			[ObjectType] [int] NULL,
			[SourceDatabaseID] [int] NULL,
			[IntegerData] [int] NULL,
			[IntegerData2] [int] NULL,
			[Offset] [int] NULL,
			[RowCounts] [bigint] NULL
		) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]	
	END
	

	IF @StoreIntoTable = 1
	BEGIN
		SET @sql = 
'INSERT INTO [dbo].[StoredTraces] 
(
	TraceTableName, AnalyzeType, [RowNumber],EventName, DurationInSeconds,
	EventClass, DatabaseID, Duration, EndTime, EventSequence, 
	IndexID, IsSystem, LoginSid, Mode, ObjectID, 
	SPID, ServerName, SessionLoginName, StartTime, TextData, 
	TransactionID, ApplicationName, ClientProcessID, DatabaseName, Error, 
	HostName, LoginName, NTDomainName, NTUserName, RequestID, 
	Severity, State, BinaryData, EventSubClass, GroupID, 
	XactSequence, IntegerData, IntegerData2,  
	LineNumber, NestLevel, ObjectName, 
	ObjectType, RowCounts, SourceDatabaseID, CPU, Offset, Reads, 
	Writes

)'
	END

	SET @SelectList = 
'SELECT TOP ' + CAST(COALESCE(@TopFilter,25) AS VARCHAR(3)) + '  '
	+ '''' + @TblName + '''' + ',' 
	+ CASE @AnalyzeType 
		WHEN 1 THEN '''ORDER BY Reads DESC'''
		WHEN 2 THEN '''ORDER BY Duration DESC'''
	  END + ', 
	t.RowNumber, te.name, t.Duration / 1000000,
	t.EventClass, t.DatabaseID, t.Duration, t.EndTime, t.EventSequence, 
	t.IndexID, t.IsSystem, t.LoginSid, t.Mode, t.ObjectID, 
	t.SPID, t.ServerName, t.SessionLoginName, t.StartTime, t.TextData, 
	t.TransactionID, t.ApplicationName, t.ClientProcessID, t.DatabaseName, t.Error, 
	t.HostName, t.LoginName, t.NTDomainName, t.NTUserName, t.RequestID, 
	t.Severity, t.State, t.BinaryData, t.EventSubClass, t.GroupID, 
	t.XactSequence, t.IntegerData, t.IntegerData2,  
	t.LineNumber, t.NestLevel, t.ObjectName, 
	t.ObjectType, t.RowCounts, t.SourceDatabaseID, t.CPU, t.Offset, t.Reads, 
	t.Writes
FROM            ADC_lockedprocess_102517 AS t INNER JOIN
                         sys.trace_events AS te ON t.EventClass = te.trace_event_id'

	SET @sql = COALESCE(@sql,' ') + @SelectList


	IF @EventTypeFilter IS NOT NULL
	BEGIN
		SET @sql += '
WHERE EventClass = ' + CAST(@EventTypeFilter AS NVARCHAR(5))
	
	END
	
	IF @AnalyzeType = 1
	BEGIN
		SET @sql += CHAR(10) + ' ORDER BY Reads DESC'
	END

	IF @AnalyzeType = 2
	BEGIN
		SET @sql += CHAR(10) + ' ORDER BY Duration DESC'
	END

	EXEC(@sql)
	PRINT @sql

END

