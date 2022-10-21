-- Disconnect all the users to this database and rollback their transaction
ALTER DATABASE x3v7 SET RESTRICTED_USER WITH ROLLBACK IMMEDIATE

SELECT name, user_access_desc, create_date, recovery_model_desc, state_desc FROM sys.databases WHERE name = 'x3v7'

-- Restore the database to the point of the snapshot
RESTORE DATABASE x3v7 FROM DATABASE_SNAPSHOT = 'x3v7_125PM'

-- Set the database back to multi-user
ALTER DATABASE x3v7 SET MULTI_USER WITH ROLLBACK IMMEDIATE
SELECT name, user_access_desc, create_date, recovery_model_desc, state_desc FROM sys.databases WHERE name = 'x3v7'