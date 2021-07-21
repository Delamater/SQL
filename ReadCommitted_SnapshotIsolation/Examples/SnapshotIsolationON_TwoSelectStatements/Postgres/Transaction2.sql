-- TRANSACTION 2
-- Step 2: Coming from transaction 1
BEGIN TRANSACTION;
	SET TRANSACTION ISOLATION LEVEL repeatable read;
	SELECT * FROM RESEARCH.EMPLOYEE WHERE ID = 1
	-- STEP 2 STOP 

	-- Stp 4: 
	SELECT * FROM RESEARCH.EMPLOYEE WHERE ID = 1
	
	-- Result is statement level read consistency. FNAME = 'BOB'

-- STEP 5: 
COMMIT 

-- STEP 6: 
SELECT * FROM RESEARCH.EMPLOYEE WHERE ID = 1
-- We now get the employee FNAME of 'BOBBY' // consistency is managed at the transaction level