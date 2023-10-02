DROP TABLE IF EXISTS dbo.SampleData 
CREATE TABLE dbo.SampleData
(
	ID INT IDENTITY(1,1),
	image image NULL,
	text text NULL,
	uniqueidentifier uniqueidentifier NULL,
	date date NULL,
	time time NULL,
	datetime2 datetime2 NULL,
	datetimeoffset	datetimeoffset NULL,
	tinyint	tinyint NULL,
	smallint	smallint NULL,
	int	int NULL,
	smalldatetime	smalldatetime NULL,
	real	real NULL,
	money	money NULL,
	datetime	datetime NULL,
	float	float NULL,
	-- sql_variant sql_variant NULL,
	ntext ntext NULL,
	bit bit NULL,
	decimal decimal(38,12) NULL,
	numeric numeric(38,12) NULL,
	smallmoney smallmoney NULL,
	bigint bigint NULL,
	varbinary varbinary(MAX) NULL,
	varchar varchar(MAX) NULL,
	binary binary(20) NULL,
	char char(1000) NULL,
	timestamp timestamp NULL,
	nvarchar nvarchar(MAX) NULL,
	sysname sysname NULL,
	nchar nchar(16) NULL
	-- hierarchyid hierarchyid NULL,
	-- geometry geometry NULL,
	-- geography geography NULL,
	-- xml xml NULL
) 



--drop function GetRandomDataForType
--CREATE OR ALTER FUNCTION GetRandomDataForType (@system_type_id int, @max_length int, @precision int, @scale int ) RETURNS @random_data TABLE 
--BEGIN 
--	--DECLARE 
--	--	@text TEXT = '123',
--	--	@uniqueidentifier uniqueidentifier = NEWID(),
--	--	@date DATE = CURRENT_TIMESTAMP,
--	--	@time TIME = CURRENT_TIMESTAMP,
--	--	@datetime2 DATETIME2 = CURRENT_TIMESTAMP,
--	--	@datetimeoffset DATETIMEOFFSET = 100,
--	--	@tinyint TINYINT = 1,
--	--	@smallint SMALLINT = 1
--	DECLARE @guid uniqueidentifier = NEWID()

--	INSERT INTO @random_data 
--	SELECT 
--		@guid,
--		GETDATE()
--		--CURRENT_TIMESTAMP,
--		--100,
--		--10,
--		--255,
--		--1024,
--		--GETDATE(),
--		--RAND(),
--		--1,
--		--CAST(NEWID() AS varbinary(16))
--		--'12345',
--		--CAST(NEWID() AS varbinary(16))
--		--'The quick Brown fox',
--		--CURRENT_TIMESTAMP,
--		--'The slow Red turtle'
--	RETURN

--END
--GO

-- select * from dbo.GetRandomDataForType(1,1,1,1)


-- DECLARE @crlf NVARCHAR(4) = CHAR(13) + CHAR(10)
-- SELECT 
-- 	OBJECT_SCHEMA_NAME(object_id) SchemaName, OBJECT_NAME(object_id) TableName, 
-- 	'INSERT INTO ' + QUOTENAME(OBJECT_SCHEMA_NAME(object_id)) + '.' + QUOTENAME(OBJECT_NAME(object_id)) + @crlf  
-- 	+ '123',
-- *
-- FROM sys.columns c
-- WHERE object_id = object_id('SEED.QUREXTRACT')

