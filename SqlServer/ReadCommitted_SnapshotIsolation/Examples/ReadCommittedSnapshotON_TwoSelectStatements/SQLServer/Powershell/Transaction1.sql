-- TRANSACTION 1

ALTER DATABASE dbtest SET ALLOW_SNAPSHOT_ISOLATION OFF;
ALTER DATABASE dbtest SET READ_COMMITTED_SNAPSHOT ON;

GO
USE dbtest
GO


-- STEP 1 -> Then go to transaction 2
BEGIN TRANSACTION
	SET TRANSACTION ISOLATION LEVEL READ COMMITTED
	UPDATE RESEARCH.EMPLOYEE
	SET FNAME = 'BOB'
	WHERE ID = 1



-- STEP 3: Coming from tansaction 2 perform the commit by itself
--COMMIT

-- STEP 4: Check the other connection, you should have the following message: 
/* 
There is no error that occurs at this point
*/
