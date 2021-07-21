IF db_id('dbtest') IS NOT NULL
BEGIN
    PRINT 'Dropping database dbtest'
    DROP DATABASE dbtest
END

CREATE DATABASE dbtest
GO
ALTER DATABASE dbtest SET ALLOW_SNAPSHOT_ISOLATION OFF
ALTER DATABASE dbtest SET READ_COMMITTED_SNAPSHOT ON