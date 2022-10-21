DROP FUNCTION IF EXISTS RESEARCH.GetPageSplitsDelta
GO

CREATE FUNCTION RESEARCH.GetPageSplitsDelta (@CurrentSplits INT)
RETURNS INT
AS
BEGIN
     RETURN(SELECT @CurrentSplits - (SELECT cntr_value FROM sys.dm_os_performance_counters WHERE counter_name = 'Page Splits/sec'))
END
GO
