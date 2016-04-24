CREATE TABLE SampleData
(
	ID				INT	IDENTITY(1,1),
	SocialSecurity	VARCHAR(256),
	Notes			VARCHAR(256),
	StateID			CHAR(2)
)
GO
WITH
	Person AS (SELECT CHECKSUM(NEWID()) AS SocialSecurity, NEWID() AS Notes),
	States AS (SELECT SUBSTRING(CAST(NEWID() AS VARCHAR(100)),0,3) AS StateID)
INSERT INTO SampleData(SocialSecurity, Notes, StateID)
SELECT TOP 1000000
	Person.SocialSecurity,
	Person.Notes,
	States.StateID
--INTO #
FROM Person 
	CROSS JOIN States 
	CROSS JOIN sys.columns 
	CROSS JOIN sys.objects

sp_spaceused SampleData
--CREATE UNIQUE NONCLUSTERED INDEX idx1 ON SampleData(ID, SocialSecurity, Notes, StateID)
--CREATE UNIQUE Clustered INDEX idx2 ON SampleData(ID, SocialSecurity, Notes, StateID)
--DROP TABLE SampleData
