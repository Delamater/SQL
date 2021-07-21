-- TRANSACTION 2
USE dbtest
GO

-- Step 2: Coming from transaction 1
BEGIN TRANSACTION
	SET TRANSACTION ISOLATION LEVEL SNAPSHOT
	UPDATE RESEARCH.EMPLOYEE
	SET FNAME = 'Billy'
	WHERE ID = 1

-- STEP 4: Once step 3 has been completed, you should get this error
/*
Msg 3960, Level 16, State 3, Line 8
Snapshot isolation transaction aborted due to update conflict. You cannot use snapshot isolation to access table 'RESEARCH.EMPLOYEE' directly or indirectly in database 'dbtest' to update, delete, or insert the row that has been modified or deleted by another transaction. Retry the transaction or change the isolation level for the update/delete statement.
*/

