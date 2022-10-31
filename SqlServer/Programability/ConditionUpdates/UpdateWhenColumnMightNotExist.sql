-- Clean up
USE master
GO
DROP DATABASE IF EXISTS testTsqlDb
GO
CREATE DATABASE testTsqlDb
GO
USE testTsqlDb
GO
CREATE SCHEMA GX
GO

/****************************** Toggle Statement For Testing ******************************/
--CREATE TABLE GX.ADOSSIER(ID INT PRIMARY KEY IDENTITY(1,1), COL1_0 INT)
CREATE TABLE GX.ADOSSIER(ID INT PRIMARY KEY IDENTITY(1,1), COL1_0 INT, COL2_0 INT)
/******************************************************************************************/

GO  -- This controls the batch compiler. If commented out, the code below behaves differently. But, you might not be able to control this GO statement in an ODBC scenario, so I show dynamic SQL use below instead. 

-- INSERT record used for update later
INSERT INTO GX.ADOSSIER(COL1_0) VALUES(99)
SELECT * FROM GX.ADOSSIER
DECLARE @flag INT
IF EXISTS(
	SELECT 1 
	FROM sys.tables t
		INNER JOIN sys.schemas s
			ON t.schema_id = s.schema_id
		INNER JOIN sys.columns c
			ON t.object_id = c.object_id
	WHERE 
		s.name = 'GX'
		AND t.name = 'ADOSSIER'
		AND c.name = 'COL2_0'
)
	BEGIN
		-- Without dynamic SQL, the UPDATE statement would be evaluated at the batch level. In some cases, if the COL2_0 doesn't exist, then an invalid column error would occur. 
		--		Dynamic SQL pushes the compilation of the query plan to be built only when the condition evaluates to true.
		-- Specifically, EXEC dynamic SQL used instead of sp_executesql for 
		--		1) brevity, 
		--		2) because we aren't parameterizing the query and 
		--		3) because this query won't execute often, so we don't care about performance
		EXEC('UPDATE GX.ADOSSIER SET COL2_0 = 1')
	END
ELSE
	BEGIN
		PRINT 'Not found'
	END



SELECT * FROM GX.ADOSSIER

