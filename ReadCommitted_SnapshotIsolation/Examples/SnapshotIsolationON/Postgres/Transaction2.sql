-- TRANSACTION 2
-- STEP 2 -> Then go to transaction 2
BEGIN TRANSACTION;
	SET TRANSACTION ISOLATION LEVEL repeatable read;
	UPDATE RESEARCH.EMPLOYEE
	SET FNAME = 'BOBBY'
	WHERE ID = 1



-- STEP 4: Coming from tansaction 1, check errors, you should now have the following: 
/*
ERROR:  could not serialize access due to concurrent update
SQL state: 40001
*/
COMMIT -- no errors
-- ROLLBACK 