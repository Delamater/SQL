-- TRANSACTION 1
USE dbtest
GO

-- STEP 1 -> Then go to transaction 2
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
BEGIN TRANSACTION
	UPDATE RESEARCH.EMPLOYEE
	SET FNAME = 'BOB'
	WHERE ID = 1



-- STEP 3: Coming from tansaction 2 perform the commit by itself
--COMMIT -- no errors
-- ROLLBACK 

-- STEP 5: No errors are present