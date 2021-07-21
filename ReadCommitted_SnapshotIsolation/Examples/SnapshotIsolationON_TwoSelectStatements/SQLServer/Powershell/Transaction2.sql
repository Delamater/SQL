-- TRANSACTION 2
USE dbtest
GO

-- Step 2: Coming from transaction 1
BEGIN TRANSACTION
	SET TRANSACTION ISOLATION LEVEL SNAPSHOT
	SELECT * FROM RESEARCH.EMPLOYEE WHERE ID = 1
	-- STEP 2 STOP 
	-- change from transaction 1 is not seen, value for fname is still a GUID

	-- Step 4: 
	SELECT * FROM RESEARCH.EMPLOYEE WHERE ID = 1
	-- change from transaction 1 is not seen, value for fname is still a GUID

-- STEP 5: 
COMMIT 

-- STEP 6: 
SELECT * FROM RESEARCH.EMPLOYEE WHERE ID = 1
-- We now get the employee FNAME of 'BOB' // consistency is managed at the transaction level