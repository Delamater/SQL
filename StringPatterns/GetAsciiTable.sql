SET NOCOUNT ON
DECLARE @AsciiTable AS TABLE
(
		ID					INT	PRIMARY KEY IDENTITY(1,1),
		AsciiCode			INT NOT NULL,
		Representation		VARCHAR(5) NOT NULL,
		IsSpecial			BIT	NOT NULL
)

DECLARE @i INT
SET @i = 0
WHILE @i < 256
BEGIN
	INSERT INTO @AsciiTable(AsciiCode, Representation, IsSpecial)
	SELECT 
		@i, 
		CHAR(@i), 
		CASE 
			WHEN @i < 32 THEN 1
			WHEN @i > 126 THEN 1
			ELSE 0
		END

	SET @i = @i+1
END

SELECT * 
FROM @AsciiTable
