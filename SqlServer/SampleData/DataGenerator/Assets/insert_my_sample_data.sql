--DECLARE @varbinary BINARY(2) = 123456, @binary
INSERT INTO dbo.SampleData 
(
	text, 
	uniqueidentifier, 
	date, 
	time, 
	datetime2, 
	datetimeoffset, 
	tinyint, 
	smallint, 
	real, 
	money, 
	datetime, 
	float, 
	-- sql_variant, 
	ntext, 
	bit, 
	decimal,
	numeric, 
	smallmoney, 
	bigint, 
	varbinary, 
	varchar, 
	binary, 
	char, 
	--timestamp, 
	nvarchar, 
	sysname, 
	nchar
	-- hierarchyid, 
	--geometry, 
	--geography, 
	--xml
)
SELECT 
	REPLICATE('ABC',50),															-- text
	NEWID(),																		-- uniqueidentifier
	GETDATE(),																		-- date
	GETDATE(),																		-- time
	GETDATE(),																		-- datetime2
	CAST(CURRENT_TIMESTAMP -8 AS datetimeoffset),									-- datetimeoffset
	10,																				-- tinyint
	255,																			-- smallint
	1024,																			-- real
	1024.10,																		-- money
	CURRENT_TIMESTAMP,																-- datetime
	1234.56789,																		-- float
																					-- sql_variant
	REPLICATE('NTEXT',50),															-- ntext
	1,																				-- bit
	1234.5678,																		-- decimal
	1234.10,																		-- numeric
	123.10,																			-- smallmoney
	99999999,																		-- bigint
	CAST( 123456 AS BINARY(20) ) ,													-- varbinary
	CHECKSUM(NEWID()),																-- varchar
	CAST( 123456 AS BINARY(20) ),																		-- binary
	CHECKSUM(NEWID()),																-- char
	--CURRENT_TIMESTAMP,															-- timestamp
	REPLICATE('nvarchar',50),													-- nvarchar
	'SOMENAME',																		-- sysname
	CHECKSUM(NEWID())																-- nchar
																					-- hierarchyid
																					--geometry
																					--xml

-- INSERT INTO SampleData(image, text, uniqueidentifier, date, time, datetime2, datetimeoffset, tinyint, smallint, int, smalldatetime, real, money, datetime, float, ntext, 
--                   bit, decimal, numeric, smallmoney, bigint, varbinary, varchar, binary, char, nvarchar, sysname, nchar)
-- SELECT s.image, s.text, s.uniqueidentifier, s.date, s.time, s.datetime2, 
-- 		s.datetimeoffset, s.tinyint, s.smallint, s.int, s.smalldatetime, s.real, s.money, s.datetime, 
-- 		s.float, ntext, s.bit, s.decimal, s.numeric, s.smallmoney, s.bigint, s.varbinary, 
-- 		s.varchar, s.binary, s.char, s.nvarchar, s.sysname, s.nchar
-- FROM     SampleData s


