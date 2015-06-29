PRINT 'Created #SQLErrorLog...'
CREATE TABLE #SQLErrorLog
(Recorded DATETIME NULL,
 ProcessInfo VARCHAR(20) NULL,
 Msg VARCHAR(MAX) NULL ) ;

PRINT 'Adding log data to #SQLErrorLog...'
INSERT INTO #SQLErrorLog (Recorded, ProcessInfo, Msg)
EXEC master.dbo.xp_readerrorlog 0;

INSERT INTO #SQLErrorLog (Recorded, ProcessInfo, Msg)
EXEC master.dbo.xp_readerrorlog 1;

INSERT INTO #SQLErrorLog (Recorded, ProcessInfo, Msg)
EXEC master.dbo.xp_readerrorlog 2;

INSERT INTO #SQLErrorLog (Recorded, ProcessInfo, Msg)
EXEC master.dbo.xp_readerrorlog 3;

INSERT INTO #SQLErrorLog (Recorded, ProcessInfo, Msg)
EXEC master.dbo.xp_readerrorlog 4;

INSERT INTO #SQLErrorLog (Recorded, ProcessInfo, Msg)
EXEC master.dbo.xp_readerrorlog 5;

INSERT INTO #SQLErrorLog (Recorded, ProcessInfo, Msg)
EXEC master.dbo.xp_readerrorlog 6;

SELECT * FROM #SQLErrorLog where Msg like 'Setting database option READ_COMMITTED_SNAPSHOT to ON for database%' ORDER BY Recorded DESC
