DROP PROCEDURE IF EXISTS dbo.CreateSampleData2
GO
CREATE PROCEDURE dbo.CreateSampleData2 @IsOptimized BIT, @IsHeap BIT AS

DROP TABLE IF EXISTS dbo.SampleData_SCHEMA_ONLY
DROP TABLE IF EXISTS dbo.SampleData_SCHEMA_AND_DATA
DROP TABLE IF EXISTS dbo.SampleData2

IF @IsOptimized = 1
BEGIN
	CREATE TABLE dbo.SampleData_SCHEMA_ONLY
	(
		ID				INT	IDENTITY(1,1),
		SocialSecurity	VARCHAR(256),
		Notes			VARCHAR(256),
		StateID			CHAR(2)

		CONSTRAINT pk_ID2 PRIMARY KEY NONCLUSTERED(ID DESC)
	) WITH(MEMORY_OPTIMIZED=ON, DURABILITY=SCHEMA_ONLY)
	PRINT 'dbo.SampleData_SCHEMA_ONLY created'

	CREATE TABLE dbo.SampleData_SCHEMA_AND_DATA
	(
		ID				INT	IDENTITY(1,1),
		SocialSecurity	VARCHAR(256),
		Notes			VARCHAR(256),
		StateID			CHAR(2)

		CONSTRAINT pk_ID3 PRIMARY KEY NONCLUSTERED(ID DESC)
	) WITH(MEMORY_OPTIMIZED=ON, DURABILITY=SCHEMA_AND_DATA)

	PRINT 'dbo.SampleData_SCHEMA_AND_DATA created'

	IF (@IsHeap) <> 1 
	BEGIN
		CREATE CLUSTERED INDEX clsSampleData_SCHEMA_ONLY ON dbo.SampleData_SCHEMA_ONLY(ID)
		CREATE CLUSTERED INDEX clsSampleData_SCHEMA_AND_DATA ON dbo.SampleData_SCHEMA_AND_DATA(ID)
	END


	INSERT INTO dbo.SampleData_SCHEMA_ONLY(SocialSecurity, Notes, StateID)
	VALUES('1111111111', 'This is some note', 'CA'), ('2222222222', 'This is some note', 'CO'), ('3333333333', 'This is some note', 'AZ')
	INSERT INTO dbo.SampleData_SCHEMA_ONLY(SocialSecurity, Notes, StateID)
	VALUES('1111111111', 'This is some note', 'CA'), ('2222222222', 'This is some note', 'CO'), ('3333333333', 'This is some note', 'AZ')
	PRINT 'SampleData_SCHEMA_ONLY data inserted'

	INSERT INTO dbo.SampleData_SCHEMA_AND_DATA(SocialSecurity, Notes, StateID)
	VALUES('1111111111', 'This is some note', 'CA'), ('2222222222', 'This is some note', 'CO'), ('3333333333', 'This is some note', 'AZ')
	INSERT INTO dbo.SampleData_SCHEMA_AND_DATA(SocialSecurity, Notes, StateID)
	VALUES('1111111111', 'This is some note', 'CA'), ('2222222222', 'This is some note', 'CO'), ('3333333333', 'This is some note', 'AZ')
	PRINT 'SampleData_SCHEMA_AND_DATA data inserted'
	
END
ELSE
BEGIN
	CREATE TABLE dbo.SampleData2
	(
		ID				INT	IDENTITY(1,1),
		SocialSecurity	VARCHAR(256),
		Notes			VARCHAR(256),
		StateID			CHAR(2)

		CONSTRAINT pk_ID2 PRIMARY KEY NONCLUSTERED(ID)
	)

	IF (@IsHeap) <> 1 
	BEGIN
		CREATE CLUSTERED INDEX clsSampleData2 ON dbo.SampleData2(ID)
	END

	INSERT INTO dbo.SampleData2(SocialSecurity, Notes, StateID)
	VALUES('1111111111', 'This is some note', 'CA'), ('2222222222', 'This is some note', 'CO'), ('3333333333', 'This is some note', 'AZ')

END


PRINT 'Procedure complete'