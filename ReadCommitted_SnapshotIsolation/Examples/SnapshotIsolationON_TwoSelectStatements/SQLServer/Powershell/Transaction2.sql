-- TRANSACTION 2
USE dbtest
GO

-- Step 2: Coming from transaction 1
SET TRANSACTION ISOLATION LEVEL SNAPSHOT
BEGIN TRANSACTION
	SELECT * FROM RESEARCH.EMPLOYEE WHERE ID = 1
	-- STEP 2 STOP 

	-- Stp 4: 
	SELECT * FROM RESEARCH.EMPLOYEE WHERE ID = 1
	
	-- Result is statement level read consistency. FNAME = 'BOB'

-- STEP 5: 
COMMIT 

-- STEP 6: 
SELECT * FROM RESEARCH.EMPLOYEE WHERE ID = 1
-- We now get the employee FNAME of 'BOB' // consistency is managed at the transaction level