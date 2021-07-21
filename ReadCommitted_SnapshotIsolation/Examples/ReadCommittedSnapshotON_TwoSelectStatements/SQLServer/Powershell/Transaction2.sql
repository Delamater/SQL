-- TRANSACTION 2
USE dbtest
GO

-- Step 2: Coming from transaction 1
BEGIN TRANSACTION
	SET TRANSACTION ISOLATION LEVEL READ COMMITTED
	SELECT * FROM RESEARCH.EMPLOYEE WHERE ID = 1
	-- STEP 2 STOP 

	-- Stp 4: 
	SELECT * FROM RESEARCH.EMPLOYEE WHERE ID = 1
	
	-- Result is statement level read consistency. FNAME = 'BOB'
-- COMMIT -- just to close the transaction, but not needed for the example