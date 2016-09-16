-- DROP TABLE SampleData
CREATE TABLE SampleData
(
	ID					INT	IDENTITY(1,1),
	SocialSecurity		VARCHAR(256),
	Notes				VARCHAR(256),
	StateID				CHAR(2),
	WageRate			DECIMAL(18,2),
	WorkHoursPerWeek	DECIMAL(18,2),
	WeeklyPay AS WageRate * WorkHoursPerWeek PERSISTED
)
GO
WITH
	Person AS (SELECT CHECKSUM(NEWID()) AS SocialSecurity, NEWID() AS Notes),
	States AS (SELECT SUBSTRING(CAST(NEWID() AS VARCHAR(100)),0,3) AS StateID)
INSERT INTO SampleData(SocialSecurity, Notes, StateID, WageRate, WorkHoursPerWeek)
SELECT TOP 1000000
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

--sp_spaceused SampleData
--CREATE UNIQUE NONCLUSTERED INDEX idx1 ON SampleData(ID, SocialSecurity, Notes, StateID)
--CREATE UNIQUE Clustered INDEX idx2 ON SampleData(ID, SocialSecurity, Notes, StateID)
--DROP TABLE SampleData
