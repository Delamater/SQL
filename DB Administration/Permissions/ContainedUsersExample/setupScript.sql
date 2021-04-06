-- Set server to allow contained databases. This is also configurable on AWS RDS and Azure
sp_configure 'contained database authentication', 1;  
GO  
RECONFIGURE;
GO
CREATE DATABASE ContainedDBTest WITH TRUSTWORTHY ON
GO

USE [master]
GO
ALTER DATABASE [ContainedDBTest] SET CONTAINMENT = PARTIAL WITH NO_WAIT
GO

USE [ContainedDBTest]
GO

-- If Local Security Policy "Password must meet complexity requirements" is enabled, a complex password must be created
CREATE USER SEED WITH PASSWORD= 'pass1234'



-- Create schema
GO
CREATE SCHEMA SEED
GO
EXEC sp_addrole @rolename = 'SEED_ADX'
EXEC sp_addrole @rolename = 'SEED_ADX_R' 

GRANT ALTER, CONTROL ON SCHEMA::SEED TO SEED_ADX
--GRANT SELECT ON SCHEMA::SEED TO SEED_ADX
GRANT SELECT ON SCHEMA::SEED TO SEED_ADX_R
GRANT ALTER ANY ROLE TO SEED

--ALTER ROLE [db_owner] ADD MEMBER SEED
--ALTER ROLE  db_securityadmin ADD MEMBER SEED
GO
CREATE FUNCTION SEED.Connections()
RETURNS @x TABLE(session_id INT, connect_time DATETIME)
WITH EXECUTE AS OWNER
AS 
BEGIN
	INSERT INTO @x(session_id, connect_time)
	SELECT session_id, connect_time FROM sys.dm_exec_connections
	RETURN;
END
GO
GRANT SELECT ON SEED.Connections TO SEED
GO

CREATE FUNCTION SEED.Connections2() 
RETURNS @x TABLE(session_id INT, connect_time DATETIME)
WITH EXECUTE AS 'dbo', ENCRYPTION
AS 
BEGIN
	INSERT INTO @x(session_id, connect_time)
	SELECT session_id, connect_time FROM sys.dm_exec_connections
	RETURN;
END
GO
GRANT SELECT ON SEED.Connections2 TO SEED

GO

CREATE FUNCTION SEED.Connections3()
RETURNS @x TABLE(session_id INT, connect_time DATETIME)
WITH EXECUTE AS SELF
AS 
BEGIN
	INSERT INTO @x(session_id, connect_time)
	SELECT session_id, connect_time FROM sys.dm_exec_connections
	RETURN;
END
GO
GRANT SELECT ON SEED.Connections3 TO SEED


