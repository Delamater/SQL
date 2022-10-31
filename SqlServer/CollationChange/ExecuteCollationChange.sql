BEGIN TRAN

	DECLARE @startTime DATETIME, @endTime DATETIME
	SET @startTime = CURRENT_TIMESTAMP
	--WAITFOR DELAY '00:00:02';
	exec dbo.uspAlterCollationMethod @NewCollateMethod = 'latin1_general_bin2'

	SET @endTime = CURRENT_TIMESTAMP
	SELECT DATEDIFF(second, @startTime, @endTime) AS Duration_Seconds
	
ROLLBACK
