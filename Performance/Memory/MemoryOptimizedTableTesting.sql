IF OBJECT_ID('dbo.uspTestMemoryOptimizedTables', 'P') IS NOT NULL
BEGIN
	PRINT 'Recreating Procedure: dbo.uspTestMemoryOptimizedTables'
	DROP PROCEDURE dbo.uspTestMemoryOptimizedTables 
END
GO


/* You must have Memory optimized tables set up like the following:
ALTER DATABASE TestDB ADD FILEGROUP Testing_Mod CONTAINS MEMORY_OPTIMIZED_DATA
ALTER DATABASE TestDB ADD FILE(name='Testing_mod1', filename='F:\data\SQL\MSSQL12.MSSQLSERVER\MSSQL\DATA\Testing_mod1') TO FILEGROUP Testing_Mod
ALTER DATABASE TestDB SET MEMORY_OPTIMIZED_ELEVATE_TO_SNAPSHOT=ON
*/


IF OBJECT_ID('dbo.uspDoInsertsSetBased', 'P') IS NOT NULL
BEGIN
	PRINT 'Recreating Procedure: dbo.uspDoInsertsSetBased'
	DROP PROCEDURE dbo.uspDoInsertsSetBased
END
GO
CREATE PROCEDURE dbo.uspDoInsertsSetBased @RowsToInsert INT
AS

SET NOCOUNT ON


DECLARE @strSQL NVARCHAR(MAX)

SET @strSQL = 
'WITH
	Person AS (SELECT CHECKSUM(NEWID()) AS SocialSecurity, NEWID() AS Notes),
	States AS (SELECT SUBSTRING(CAST(NEWID() AS VARCHAR(100)),0,3) AS StateID)
INSERT INTO SampleData(SocialSecurity, Notes, StateID)
SELECT TOP ' + CAST(@RowsToInsert AS VARCHAR(10)) + '
	Person.SocialSecurity,
	Person.Notes,
	States.StateID
--INTO #
FROM Person 
	CROSS JOIN States 
	CROSS JOIN sys.columns 
	CROSS JOIN sys.objects'

EXEC(@strSQL)

GO



IF OBJECT_ID('dbo.uspDoInsertsIteratively', 'P') IS NOT NULL
BEGIN
	PRINT 'Recreating Procedure: dbo.uspDoInsertsIteratively'
	DROP PROCEDURE dbo.uspDoInsertsIteratively
END
GO
CREATE PROCEDURE dbo.uspDoInsertsIteratively @LoopCount INT
AS

SET NOCOUNT ON

DECLARE @i INT
SET @i = 1

WHILE @i <= @LoopCount
BEGIN
	WITH
		Person AS (SELECT CHECKSUM(NEWID()) AS SocialSecurity, NEWID() AS Notes),
		States AS (SELECT SUBSTRING(CAST(NEWID() AS VARCHAR(100)),0,3) AS StateID)
	INSERT INTO SampleData(SocialSecurity, Notes, StateID)
	SELECT TOP 1 --1000000
		Person.SocialSecurity,
		Person.Notes,
		States.StateID
	--INTO #
	FROM Person 
		CROSS JOIN States 
		CROSS JOIN sys.columns 
		CROSS JOIN sys.objects

	SET @i+= 1
END
GO

IF OBJECT_ID('dbo.DoSelects', 'P') IS NOT NULL
BEGIN
	PRINT 'Recreating Procedure: dbo.DoSelects'
	DROP PROCEDURE dbo.DoSelects
END
GO
CREATE PROCEDURE dbo.DoSelects AS
SET NOCOUNT ON

DECLARE @i INT, @throwResultsAway INT
SET @i = 1
WHILE @i <= (SELECT MAX(ID) FROM dbo.SampleData)
BEGIN
	SET @throwResultsAway = (select ID from dbo.SampleData WHERE ID = @i)
	SET @i+=1
END



GO


IF OBJECT_ID('dbo.DoDeletes', 'P') IS NOT NULL
BEGIN
	PRINT 'Recreating Procedure: dbo.DoDeletes'
	DROP PROCEDURE dbo.DoDeletes
END
GO
CREATE PROCEDURE dbo.DoDeletes AS
SET NOCOUNT ON

DECLARE @i INT = 1
BEGIN TRAN
	WHILE @i <= (SELECT MAX(ID) FROM dbo.SampleData)
	BEGIN
		-- Delete every other row, then roll back the transaction
		DELETE dbo.SampleData WHERE ID = @i
	
		SET @i+=1
	END
ROLLBACK

GO

IF OBJECT_ID('dbo.DoDeletesSetBased', 'P') IS NOT NULL
BEGIN
	PRINT 'Recreating Procedure: dbo.DoDeletesSetBased'
	DROP PROCEDURE dbo.DoDeletesSetBased
END
GO
CREATE PROCEDURE dbo.DoDeletesSetBased AS
SET NOCOUNT ON

BEGIN TRAN
	DELETE dbo.SampleData 
ROLLBACK

GO

IF OBJECT_ID('dbo.DoUpdates', 'P') IS NOT NULL
BEGIN
	PRINT 'Recreating Procedure: dbo.DoUpdates'
	DROP PROCEDURE dbo.DoUpdates
END
GO

CREATE PROCEDURE dbo.DoUpdates AS
SET NOCOUNT ON

DECLARE @i INT = 1

BEGIN TRAN
WHILE @i <= (SELECT MAX(ID) FROM dbo.SampleData)
	BEGIN
	
		UPDATE dbo.SampleData
		SET SocialSecurity = SocialSecurity * -1
		WHERE ID = @i

		SET @i += 1	
	END
ROLLBACK	
GO

IF OBJECT_ID('dbo.DoUpdatesSetBased', 'P') IS NOT NULL
BEGIN
	PRINT 'Recreating Procedure: dbo.DoUpdatesSetBased'
	DROP PROCEDURE dbo.DoUpdatesSetBased
END
GO

CREATE PROCEDURE dbo.DoUpdatesSetBased AS
SET NOCOUNT ON

BEGIN TRAN
	UPDATE dbo.SampleData
	SET SocialSecurity = SocialSecurity * -1
ROLLBACK	
GO

IF OBJECT_ID('dbo.uspTestMemoryOptimizedTables', 'P') IS NOT NULL
BEGIN
	PRINT 'Recreating Procedure: dbo.uspTestMemoryOptimizedTables'
	DROP PROCEDURE dbo.uspTestMemoryOptimizedTables
END
GO
CREATE PROCEDURE dbo.uspTestMemoryOptimizedTables @IsOptimized BIT, @LoopCount INT
AS

SET NOCOUNT ON

-- Set up SampleData table
IF OBJECT_ID('dbo.SampleData', 'U') IS NOT NULL
BEGIN
	PRINT 'Recreating Table dbo.SampleData'
	DROP TABLE dbo.SampleData
END
IF @IsOptimized = 1
BEGIN
	CREATE TABLE dbo.SampleData
	(
		ID				INT	IDENTITY(1,1),
		SocialSecurity	VARCHAR(256),
		Notes			VARCHAR(256),
		StateID			CHAR(2)

		CONSTRAINT pk_ID PRIMARY KEY NONCLUSTERED(ID)
	) WITH(MEMORY_OPTIMIZED=ON)
END
ELSE
BEGIN
	CREATE TABLE dbo.SampleData
	(
		ID				INT	IDENTITY(1,1),
		SocialSecurity	VARCHAR(256),
		Notes			VARCHAR(256),
		StateID			CHAR(2)

		CONSTRAINT pk_ID PRIMARY KEY NONCLUSTERED(ID)
	)
END


DECLARE @StartTime DATETIME, @EndTime DATETIME
DECLARE @BatchExecutionTime DATETIME, @BatchID UNIQUEIDENTIFIER


SET @BatchExecutionTime = GETDATE() -- Now
SET @BatchID = NEWID()

-- Create a log table if it doesn't already exist
IF OBJECT_ID('dbo.MemoryOptimizedTableResults', 'U') IS NULL
BEGIN
	PRINT 'Creating dbo.MemoryOptimizedTableResults'
	CREATE TABLE dbo.MemoryOptimizedTableResults
	(
		ID INT IDENTITY(1,1) PRIMARY KEY,
		Notes				VARCHAR(250),
		StartTime			DATETIME,
		EndTime				DATETIME,
		ParamValue			INT,
		BatchExecutionTime	DATETIME,
		BatchID				UNIQUEIDENTIFIER,
		IsOptimized			BIT
	)
END




---- Record Iterative Insert Results
--SET @StartTime = GETDATE()
--exec dbo.uspDoInsertsIteratively @LoopCount
--SET @EndTime = GETDATE()

--INSERT INTO dbo.MemoryOptimizedTableResults(Notes, StartTime, EndTime, ParamValue, BatchExecutionTime, BatchID) 
--VALUES('Inserts: Iteratively', @StartTime, @EndTime, @LoopCount, @BatchExecutionTime, @BatchID)


--DELETE dbo.SampleData

-- Set Based Inserts
SET @StartTime = GETDATE()
exec dbo.uspDoInsertsSetBased @LoopCount
SET @EndTime = GETDATE()

INSERT INTO dbo.MemoryOptimizedTableResults(Notes, StartTime, EndTime, ParamValue, BatchExecutionTime, BatchID, IsOptimized) 
VALUES('Inserts: Set Based', @StartTime, @EndTime, @LoopCount, @BatchExecutionTime, @BatchID, @IsOptimized)



-- DoSelects
SET @StartTime = GETDATE()
exec dbo.DoSelects --@LoopCount
SET @EndTime = GETDATE()

INSERT INTO dbo.MemoryOptimizedTableResults(Notes, StartTime, EndTime, ParamValue, BatchExecutionTime, BatchID, IsOptimized) 
VALUES('Select', @StartTime, @EndTime, @LoopCount, @BatchExecutionTime, @BatchID, @IsOptimized)


-- DoDeletes
SET @StartTime = GETDATE()
exec dbo.DoDeletes 
SET @EndTime = GETDATE()

INSERT INTO dbo.MemoryOptimizedTableResults(Notes, StartTime, EndTime, ParamValue, BatchExecutionTime, BatchID, IsOptimized) 
VALUES('Delete', @StartTime, @EndTime, @LoopCount, @BatchExecutionTime, @BatchID, @IsOptimized)

-- DoDeletesSetBased
SET @StartTime = GETDATE()
exec dbo.DoDeletesSetBased
SET @EndTime = GETDATE()

INSERT INTO dbo.MemoryOptimizedTableResults(Notes, StartTime, EndTime, ParamValue, BatchExecutionTime, BatchID, IsOptimized) 
VALUES('Delete: Set Based', @StartTime, @EndTime, @LoopCount, @BatchExecutionTime, @BatchID, @IsOptimized)


-- DoUpdates
SET @StartTime = GETDATE()
exec dbo.DoUpdates 
SET @EndTime = GETDATE()

INSERT INTO dbo.MemoryOptimizedTableResults(Notes, StartTime, EndTime, ParamValue, BatchExecutionTime, BatchID, IsOptimized) 
VALUES('Update', @StartTime, @EndTime, @LoopCount, @BatchExecutionTime, @BatchID, @IsOptimized)

-- DoUpdatesSetBased
SET @StartTime = GETDATE()
exec dbo.DoUpdatesSetBased
SET @EndTime = GETDATE()

INSERT INTO dbo.MemoryOptimizedTableResults(Notes, StartTime, EndTime, ParamValue, BatchExecutionTime, BatchID, IsOptimized) 
VALUES('Update: Set Based', @StartTime, @EndTime, @LoopCount, @BatchExecutionTime, @BatchID, @IsOptimized)


-- Report Results
SELECT ID, IsOptimized, Notes, DATEDIFF(ms, StartTime, EndTime) RunTimeMilliseconds, StartTime, EndTime, ParamValue, BatchExecutionTime, BatchID 
FROM dbo.MemoryOptimizedTableResults

GO

