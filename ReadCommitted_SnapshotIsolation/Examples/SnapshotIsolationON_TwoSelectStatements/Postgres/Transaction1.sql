-- Connection 1	
-- TRANSACTION 1
-- select * from RESEARCH.EMPLOYEE WHERE id  = 1

-- STEP 1 -> Then go to transaction 2
-- SET TRANSACTION ISOLATION LEVEL READ COMMITTED
BEGIN TRANSACTION;
	SET TRANSACTION ISOLATION LEVEL repeatable read;
	UPDATE RESEARCH.EMPLOYEE
	SET FNAME = 'BOBBY'
	WHERE ID = 1



-- STEP 3: Coming from tansaction 2 perform the commit by itself
COMMIT
-- rollback
