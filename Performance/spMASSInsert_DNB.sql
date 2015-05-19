IF EXISTS (SELECT NAME FROM sysobjects WHERE NAME = 'spMASSInsert_DNB')
   BEGIN
	 Print 'Recreating procedure: spMASSInsert_DNB'
	 DROP PROCEDURE spMASSInsert_DNB
   END
SET NOCOUNT ON
SET QUOTED_IDENTIFIER OFF
GO
/*
Author:		Bob Delamater
Description:	Insert a specific amount of rows into a table.
			The table can be one of three different types
			1. Temp DB Table
			2. Table Variable
			3. Permenant Table

			The table will consist of 5 rows. An identity row, start and stop time and two nunmbers

Parameters:	@enumTable INT (The type of table to insert into)
			   Valid Values Include:
			   1. Permenant Table = 1
			   2. Temp DB Table = 2
			   3. Table Variable = 3
			   4. In-Memory = 4
			@NumRowsToInsert INT (How many rows you want to insert)
			
		  @SelectDataAfterInsert SMALLINT 
			1 = TRUE (SELECT the data after it has been inserted)
			2 = FALSE (Do not select the data after it has been inserted)
*/

CREATE PROCEDURE spMASSInsert_DNB (@enumTable INT, @NumRowsToInsert INT, @SelectDataAfterInsert SMALLINT) AS
SET NOCOUNT ON
-- Log the start time
DECLARE  @CurrentNum INT,
	    @StartTime	 DATETIME,
	    @EndTime	 DATETIME

SET @StartTime = GETDATE()
PRINT 'Start time: ' + CAST(@StartTime AS VARCHAR(50))


SELECT @CurrentNum = 1, @StartTime = GETDATE()
-- Permenant Table testing
IF @enumTable = 1
BEGIN
PRINT 'Starting permenant table insertion testing'
   -- If table does not exists create it
   -- Using SYSOBJECTS instead of SYSOBJECTS for backwards compatibility
   -- This script will run on SQL 2000 and SQL 20005
   IF OBJECT_ID('tblMassInsert', 'U') IS NULL
	 BEGIN

	   CREATE TABLE tblMassInsert
	   (
		 InsertKey INT IDENTITY(1,1),
		 StartTime DATETIME,
		 EndTime DATETIME,
		 Number1 INT,
		 Number2 INT
	   )

	 END

	-- Clear table for input
	TRUNCATE TABLE tblMassInsert      

   -- While loop to insert number of rows
   SELECT @CurrentNum = 1

--   PRINT 'Looping now'
   WHILE @CurrentNum < @NumRowsToInsert      
   BEGIN
	  -- Main insert for @enumTable = 1
	  INSERT INTO tblMassInsert (StartTime, EndTime, Number1, Number2)
	  VALUES(@StartTime, NULL, @CurrentNum, @NumRowsToInsert)
	  SELECT @EndTime = GETDATE()
	  
	  SELECT @CurrentNum = (@CurrentNum + 1)       
   END

	  -- Update the table with the end time
	  SELECT @EndTime = GETDATE()
	  UPDATE tblMassInsert
	  SET EndTime = @EndTime

   IF @SelectDataAfterInsert = 1 
	  BEGIN
		SELECT *, EndTime - StartTime AS TotalTime FROM tblMassInsert WITH(NOLOCK)
	  END   	    
   END -- @enumTable = 1 end


-- TempDB Table Testing
IF @enumTable = 2
BEGIN
PRINT 'Starting temp DB table insertion testing'
   IF EXISTS(SELECT NAME FROM sysobjects WHERE NAME = '#tblMassInsert')
	 BEGIN
	    DROP TABLE #tblMassInsert
	 END	  
   CREATE TABLE #tblMassInsert
   (
	 InsertKey INT IDENTITY(1,1),
	 StartTime DATETIME,
	 EndTime DATETIME,
	 Number1 INT,
	 Number2 INT
   )

   -- While loop to insert number of rows
   SELECT @CurrentNum = 1

--   PRINT 'Looping now'
--   PRINT @CurrentNum
--   PRINT @NumRowsToInsert

   WHILE @CurrentNum < @NumRowsToInsert
	 BEGIN
	    -- Main insert for @enumTable = 2
	    INSERT INTO #tblMassInsert (StartTime, EndTime, Number1, Number2)
	    VALUES(@StartTime, NULL, @CurrentNum, @NumRowsToInsert)

	    SELECT @CurrentNum = (@CurrentNum + 1)       
	 END

	 -- Update the table with the end time
	 SELECT @EndTime = GETDATE()
	 UPDATE #tblMassInsert
	 SET EndTime = @EndTime

	 -- Select the data?
	IF @SelectDataAfterInsert = 1 
	 BEGIN
		SELECT *, EndTime - StartTime AS TotalTime FROM #tblMassInsert WITH(NOLOCK)
	 END  
 	    
END -- @enumTable = 2 end


-- Table Variable Testing
IF @enumTable = 3
BEGIN
   PRINT 'Starting table variable insertion testing'
   DECLARE @tblMassInsert TABLE
	 (
	   InsertKey INT IDENTITY(1,1),
	   StartTime DATETIME,
	   EndTime DATETIME,
	   Number1 INT,
	   Number2 INT
	 )
   SELECT @CurrentNum = 1

--   PRINT 'Looping now'
   WHILE @CurrentNum < @NumRowsToInsert
	 BEGIN
	    -- Main insert for @enumTable = 3
	    INSERT INTO @tblMassInsert (StartTime, EndTime, Number1, Number2)
	    VALUES(@StartTime, NULL, @CurrentNum, @NumRowsToInsert)

 	    SELECT @CurrentNum = (@CurrentNum + 1)       
	  END

    -- Update the table with the end time
    SELECT @EndTime = GETDATE()
    UPDATE @tblMassInsert
    SET EndTime = @EndTime

	 IF @SelectDataAfterInsert = 1 
	    BEGIN
		SELECT *, EndTime - StartTime AS TotalTime FROM @tblMassInsert 
	    END   	    
END -- @enumTable = 3 end

-- In-Memory Table testing
If @enumTable = 4
BEGIN
BEGIN
   PRINT 'Starting In-Memory insertion testing'
   IF OBJECT_ID('dbo.InMemory', 'U') IS NULL
	 BEGIN

	   CREATE TABLE dbo.InMemory
		 (
		   InsertKey INT IDENTITY(1,1) PRIMARY KEY NONCLUSTERED,
		   StartTime DATETIME,
		   EndTime DATETIME,
		   Number1 INT,
		   Number2 INT
		 ) WITH (MEMORY_OPTIMIZED = ON, DURABILITY=SCHEMA_AND_DATA)
	END
   SELECT @CurrentNum = 1

--   PRINT 'Looping now'
   WHILE @CurrentNum < @NumRowsToInsert
	 BEGIN
	    -- Main insert for @enumTable = 3
	    INSERT INTO dbo.InMemory (StartTime, EndTime, Number1, Number2)
	    VALUES(@StartTime, NULL, @CurrentNum, @NumRowsToInsert)

 	    SELECT @CurrentNum = (@CurrentNum + 1)       
	  END

    -- Update the table with the end time
    SELECT @EndTime = GETDATE()
    UPDATE dbo.InMemory
    SET EndTime = @EndTime

	 IF @SelectDataAfterInsert = 1 
	    BEGIN
		SELECT *, EndTime - StartTime AS TotalTime FROM dbo.InMemory 
	    END   	    

	DROP TABLE dbo.InMemory
END -- In-Memory = 4 end	
END

SET @EndTime = GETDATE()

PRINT 'End time: ' + CAST(@EndTime  AS VARCHAR(50)) 
PRINT 'Total time: ' + CAST(DATEDIFF(MS, @StartTime, @EndTime) AS VARCHAR(50)) + ' milliseconds'