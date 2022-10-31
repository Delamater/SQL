
IF OBJECT_ID('dbo.IsContainsNonAscii') IS NOT NULL
BEGIN
	PRINT 'Dropping dbo.IsContainsNonAscii'
	DROP FUNCTION dbo.IsContainsNonAscii
END
GO
/****************************** Create Function: IsContainsNonAscii ****************************/
CREATE FUNCTION dbo.IsContainsNonAscii ( @string nvarchar(max), @minAscii INT, @maxAscii INT ) 
RETURNS BIT AS 
BEGIN

	DECLARE @pos		INT = 0;
	declare @char		NVARCHAR(1);
	declare @retval		BIT = 0;

	WHILE @pos < DATALENGTH(@string)
	BEGIN
		SELECT @char = SUBSTRING(@string, @pos, 1)
		IF ASCII(@char) <= @minAscii  or ASCII(@char) >= @maxAscii 
			BEGIN
				SELECT @retval = 1;
				RETURN @retval;
			END
		ELSE
			BEGIN
				SELECT @pos = @pos + 1
			END
	END

	RETURN @retval;
END


GO

IF OBJECT_ID('dbo.t1') IS NOT NULL
BEGIN 
	DROP TABLE dbo.t1
END

CREATE TABLE dbo.t1(id int primary key identity(1,1), char1 nvarchar(max) NOT NULL, ROWID INT NOT NULL)
GO

INSERT INTO dbo.t1(char1,ROWID) select 'ùÈü', 1
INSERT INTO dbo.t1(char1,ROWID) select 'control value', 2
INSERT INTO dbo.t1(char1,ROWID) select CHAR(200), 2

--SELECT * FROM dbo.t1

SELECT *
FROM SEED.APROCTEXTE
WHERE 
	(CODPRO_0 = 'ASACH_001' AND LANG_0 = 'BRI'AND UNIQIDP_0 = '123435431735771570') 
	AND dbo.IsContainsNonAscii(CLBTEXT_0, 31,126) = 1

SELECT *
FROM SEED.APROCTEXTE
WHERE 
	(CODPRO_0 = 'ASACH_001' AND LANG_0 = 'BRI'AND UNIQIDP_0 = '1234354317357549354') 
	AND dbo.IsContainsNonAscii(CLBTEXT_0, 31,126) = 1

SELECT *
FROM dbo.t1
WHERE dbo.IsContainsNonAscii (char1, 31, 126) = 1
ORDER BY ROWID

