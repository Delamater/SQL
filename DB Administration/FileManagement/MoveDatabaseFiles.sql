-- Author: Bob Delamater			
-- Description: Informs SQL Server that you are moving the log and data files to a new location.
-- 		If a file exists in the destination path, it will be overwritten when you restart SQL Server.
--		For this reason, be absolutely careful you do not overwrite a production database file.
--Move database and log files to E drive
DECLARE @dbName SYSNAME, 
		@newLocDataFilePath	VARCHAR(255),
		@newLocLogFilePath	VARCHAR(255),

SET @newLocDataFilePath = 'E:\MyFolder\Data\x3v6_data.mdf'
SET @newLocLogFilePath = 'E:\MyFolder\Data\x3v6_log.ldf'

USE master
SELECT name, physical_name
FROM sys.master_files
WHERE database_id = DB_ID('x3v6')

ALTER DATABASE x3v6
SET OFFLINE

ALTER DATABASE  x3v6
MODIFY FILE( Name = x3v6_data, FILENAME = 'E:\MyFolder\Data\x3v6_data.mdf')
ALTER DATABASE  x3v6
MODIFY FILE( Name = x3v6_log, FILENAME = 'E:\MyFolder\Data\x3v6_log.ldf')

ALTER DATABASE x3v6
SET ONLINE

USE master
SELECT name, physical_name
FROM sys.master_files
WHERE database_id = DB_ID('x3v6')
