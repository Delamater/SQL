-- TRANSACTION 1

ALTER DATABASE dbtest SET ALLOW_SNAPSHOT_ISOLATION ON;
GO
USE dbtest
GO


-- STEP 1 -> Then go to transaction 2
SET TRANSACTION ISOLATION LEVEL SNAPSHOT
BEGIN TRANSACTION
	UPDATE RESEARCH.EMPLOYEE
	SET FNAME = 'BOB'
	WHERE ID = 1



-- STEP 3: Coming from tansaction 2 perform the commit by itself
--COMMIT

-- STEP 4: Check the other connection, you should have the following message: 
/* 
Msg 3960, Level 16, State 3, Line 7
Snapshot isolation transaction aborted due to update conflict. You cannot use snapshot isolation to access table 'RESEARCH.EMPLOYEE' directly or indirectly in database 'dbtest' to update, delete, or insert the row that has been modified or deleted by another transaction. Retry the transaction or change the isolation level for the update/delete statement.
*/
