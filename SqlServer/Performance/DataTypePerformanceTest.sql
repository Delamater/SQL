SET NOCOUNT ON
DECLARE @Limit BIGINT
SET @Limit = 20000

IF object_id('dbo.t1') IS NOT NULL
BEGIN 
	DROP TABLE dbo.t1
END

IF object_id('dbo.Num1') IS NOT NULL
BEGIN 
	DROP SEQUENCE dbo.Num1
END


DECLARE @InsertSpaceUsed TABLE(
	[name] SYSNAME,
	[rows] BIGINT,
	reserved NVARCHAR(MAX),
	data NVARCHAR(MAX),
	index_size NVARCHAR(MAX),
	unused NVARCHAR(MAX)
)

DECLARE @UpdateSpaceUsed TABLE(
	[name] SYSNAME,
	[rows] BIGINT,
	reserved NVARCHAR(MAX),
	data NVARCHAR(MAX),
	index_size NVARCHAR(MAX),
	unused NVARCHAR(MAX)
)

DECLARE @DeleteSpaceUsed TABLE(
	[name] SYSNAME,
	[rows] BIGINT,
	reserved NVARCHAR(MAX),
	data NVARCHAR(MAX),
	index_size NVARCHAR(MAX),
	unused NVARCHAR(MAX)
)

DECLARE @i BIGINT, 
	@StartInsertTime DATETIME, @EndInsertTime DATETIME,
	@StartUpdateTime DATETIME, @EndUpdateTime DATETIME,
	@StartDeleteTime DATETIME, @EndDeleteTime DATETIME

SET @i = 0
CREATE TABLE dbo.t1(ID BIGINT PRIMARY KEY, SomeText VARCHAR(2000))
--CREATE TABLE dbo.t1(ID BIGINT PRIMARY KEY)
CREATE SEQUENCE dbo.Num1 START WITH 0 INCREMENT BY 1

SET @StartInsertTime = GETDATE()
WHILE @i <= @Limit
BEGIN

	INSERT INTO t1(ID,SomeText)
	VALUES	(NEXT VALUE FOR dbo.Num1, '');
	--INSERT INTO t1(ID)
	--VALUES	(NEXT VALUE FOR dbo.Num1);
	SET @i += 1;
END
SET @EndInsertTime = GETDATE();

INSERT @InsertSpaceUsed EXEC sp_spaceused 'dbo.t1'

SET @StartUpdateTime = GETDATE();
SET @i = 0
WHILE @i <= @Limit
BEGIN
	UPDATE dbo.t1
	SET SomeText = 'AAA'
	WHERE ID = @i
	SET @i += 1
END
SET @EndUpdateTime = GETDATE();

INSERT @UpdateSpaceUsed EXEC sp_spaceused 'dbo.t1'

SET @StartDeleteTime = GETDATE();
SET @i = 0
WHILE @i <= @Limit
BEGIN
	DELETE dbo.t1
	WHERE ID = @i
	SET @i += 1
END

SET @EndDeleteTime = GETDATE();

INSERT @DeleteSpaceUsed EXEC sp_spaceused 'dbo.t1'

-- Check Results
SELECT 
	DATEDIFF(ms,@StartInsertTime, @EndInsertTime) AS InsertDuration_ms,
	DATEDIFF(ms,@StartUpdateTime, @EndUpdateTime) AS UpdateDuration_ms,
	DATEDIFF(ms,@StartDeleteTime, @EndDeleteTime) AS DeleteDuration_ms;

SELECT *, 'Insert' AS Type from @InsertSpaceUsed
UNION ALL
SELECT *, 'Insert' AS Type from @UpdateSpaceUsed
UNION ALL
SELECT *, 'Insert' AS Type from @DeleteSpaceUsed

-- Cleanup
DROP SEQUENCE dbo.Num1;
DROP TABLE dbo.t1;


