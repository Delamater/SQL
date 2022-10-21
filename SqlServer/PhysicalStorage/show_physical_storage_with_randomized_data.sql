SET NOCOUNT ON

-- Drop and Recreate Objects As Necessary
DROP TABLE IF EXISTS dbo.fragmentedData
DROP TABLE IF EXISTS dbo.recordLimiter
DROP SEQUENCE IF EXISTS dbo.fragID_seq

CREATE SEQUENCE dbo.fragID_seq START WITH 1 INCREMENT BY 1;
CREATE TABLE dbo.recordLimiter(ID INT IDENTITY(1,1), someNumber BIT)
CREATE TABLE dbo.fragmentedData(
	ID INT NOT NULL, 
	UnorderedString NVARCHAR(40) NOT NULL,
	OrderedString UNIQUEIDENTIFIER DEFAULT NEWSEQUENTIALID() NOT NULL,
	LargeString NVARCHAR(MAX) NOT NULL	
)

ALTER TABLE dbo.fragmentedData ADD CONSTRAINT PK_fragmentedData_UnorderedString PRIMARY KEY(ID)

-- Stub out a limit for records
INSERT INTO dbo.recordLimiter(someNumber) 
SELECT TOP 1000 1 FROM sys.columns c

-- Create Sample Data. At this point the page_id values will increment normally along with the ID column
INSERT INTO dbo.fragmentedData(ID, UnorderedString, LargeString)
SELECT (NEXT VALUE FOR dbo.fragID_seq), CAST(NEWID() AS NVARCHAR(40)), REPLICATE(CAST(NEWID() AS NVARCHAR(40)),40)
FROM dbo.recordLimiter


-- Demonstrate ID values increment along with page_id
SELECT loc.*, f.* 
FROM dbo.fragmentedData f
	CROSS APPLY sys.fn_PhysLocCracker(%%physloc%%) loc
ORDER BY page_id

-- Fragment the data 
ALTER TABLE dbo.fragmentedData DROP CONSTRAINT PK_fragmentedData_UnorderedString WITH ( ONLINE = OFF )
ALTER TABLE dbo.fragmentedData ADD CONSTRAINT PK_fragmentedData_UnorderedString PRIMARY KEY(UnorderedString)

-- Demonstrate the ID column is now randomly ordered
SELECT loc.*, f.* 
FROM dbo.fragmentedData f
	CROSS APPLY sys.fn_PhysLocCracker(%%physloc%%) loc
ORDER BY page_id

