DECLARE @NumberOfDaysToCalculateRollingAverage INT,
		@NumberOfMinutesInPeriod INT
SET @NumberOfDaysToCalculateRollingAverage = 30

SET @NumberOfMinutesInPeriod = (@NumberOfDaysToCalculateRollingAverage * 24) * 60
SELECT 
	DATEDIFF(day, login_time, GETDATE()) AS SystemUpTime_Days,
	DATEDIFF(hour, login_time, GETDATE()) AS SystemUpTime_Hours,
	DATEDIFF(mi, login_time, GETDATE()) AS SystemUpTime_Minutes
FROM master..sysprocesses WHERE spid = 1 
