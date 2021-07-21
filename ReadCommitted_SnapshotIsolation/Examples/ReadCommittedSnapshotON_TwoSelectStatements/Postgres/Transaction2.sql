-- TRANSACTION 2
-- Step 2: Coming from transaction 1
BEGIN TRANSACTION;
	SELECT fname FROM RESEARCH.EMPLOYEE WHERE ID = 1
	-- STEP 2 STOP 
	-- Result: 'Bob', the original value

	-- Stp 4: 
	SELECT fname FROM RESEARCH.EMPLOYEE WHERE ID = 1
	
	-- Result is statement level read consistency. FNAME = 'BOBBY'

-- STEP 5: Only needed to end the transaction, functional test is already done
-- COMMIT 
-- rollback
