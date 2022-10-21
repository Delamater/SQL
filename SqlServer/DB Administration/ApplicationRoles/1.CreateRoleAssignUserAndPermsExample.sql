-- Script 1 of 2
-- Setup
CREATE DATABASE dbTest01
GO
USE dbTest01
GO
/**************************************************************************************************/
-- sp_addrolemember example
/**************************************************************************************************/

CREATE LOGIN [BOB01] WITH PASSWORD=N'pass1234', DEFAULT_DATABASE=master, CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
GO
USE dbTest01
GO
CREATE USER [BOB01] FOR LOGIN [BOB01]
GO
EXEC sp_addrole @rolename = 'Production'
GRANT ALTER ANY ROLE TO BOB01
REVOKE ALTER ANY ROLE TO BOB01
EXEC sp_addrolemember 'db_securityadmin', @membername = 'BOB01'
EXEC sp_droprolemember 'db_securityadmin', @membername = 'BOB01'

-- Teardown
--DROP USER BOB01
--GO
--USE master
--GO
--DROP LOGIN BOB01
--GO
--DROP DATABASE dbTest01



