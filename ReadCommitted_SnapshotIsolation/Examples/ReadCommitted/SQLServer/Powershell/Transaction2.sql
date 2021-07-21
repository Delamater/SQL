-- TRANSACTION 2
USE dbtest
GO

-- STEP 1 -> Then go to transaction 2
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
BEGIN TRANSACTION
	UPDATE RESEARCH.EMPLOYEE
	SET FNAME = 'BOBBY'
	WHERE ID = 1

	-- We are blocked
-- STEP 4: We are unblocked, now commit your transaction
COMMIT -- No errors