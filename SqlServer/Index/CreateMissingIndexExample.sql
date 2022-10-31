--ALTER DATABASE SampleData SET QUERY_STORE = ON

DROP TABLE IF EXISTS SampleData;
CREATE TABLE SampleData
(
	ID					INT	IDENTITY(1,1),
	SocialSecurity		VARCHAR(256),
	Notes				VARCHAR(256),
	StateID				CHAR(2),
	WageRate			DECIMAL(18,2),
	WorkHoursPerWeek	DECIMAL(18,2),
	WeeklyPay AS WageRate * WorkHoursPerWeek PERSISTED
) WITH (DATA_COMPRESSION = ROW)
GO
WITH
	Person AS (SELECT CHECKSUM(NEWID()) AS SocialSecurity, NEWID() AS Notes),
	States AS (SELECT SUBSTRING(CAST(NEWID() AS VARCHAR(100)),0,3) AS StateID)
INSERT INTO SampleData(SocialSecurity, Notes, StateID, WageRate, WorkHoursPerWeek)
SELECT TOP 100000
	Person.SocialSecurity,
	Person.Notes,
	States.StateID,
	ABS(CHECKSUM(NewId())) % 501, -- Pay rate can be anywhere from 0 to 500 per hour
	ABS(CHECKSUM(NewId())) % 81		-- Worked hours can be anywhere from 0 to 80 hours worked a week
--INTO #
FROM Person 
	CROSS JOIN States 
	CROSS JOIN sys.columns 
	CROSS JOIN sys.objects
	CROSS JOIN sys.tables

sp_spaceused SampleData

-- Creating an index on a field not filtered in the query is necessary
-- for the missing index to occur otherwise it would be a trivial plan. 
-- Trivial plans are not considered for the missing indexes feature. 
CREATE NONCLUSTERED INDEX idxNotes ON SampleData(Notes)

SELECT * 
FROM SampleData
WHERE WageRate = 52 AND SocialSecurity > 100000 

--DROP INDEX idxNotes on SampleData


--SELECT TOP 10 rs.avg_physical_io_reads, qt.query_sql_text,   
--    q.query_id, qt.query_text_id, p.plan_id, rs.runtime_stats_id,   
--    rsi.start_time, rsi.end_time, rs.avg_rowcount, rs.count_executions  
--FROM sys.query_store_query_text AS qt   
--JOIN sys.query_store_query AS q   
--    ON qt.query_text_id = q.query_text_id   
--JOIN sys.query_store_plan AS p   
--    ON q.query_id = p.query_id   
--JOIN sys.query_store_runtime_stats AS rs   
--    ON p.plan_id = rs.plan_id   
--JOIN sys.query_store_runtime_stats_interval AS rsi   
--    ON rsi.runtime_stats_interval_id = rs.runtime_stats_interval_id  
--WHERE rsi.start_time >= DATEADD(hour, -24, GETUTCDATE())   
--ORDER BY rs.avg_physical_io_reads DESC; 
