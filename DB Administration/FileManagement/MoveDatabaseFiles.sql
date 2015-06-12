--Move database and log files to E drive
DECLARE @dbName SYSNAME, 
		@newLocDataFilePath	VARCHAR(255),
		@newLocLogFilePath	VARCHAR(255),

SET @newLocDataFilePath = 'E:\Elmer\Data\x3v6_data.mdf'
SET @newLocLogFilePath = 'E:\Elmer\Data\x3v6_log.ldf'

USE master
SELECT name, physical_name
FROM sys.master_files
WHERE database_id = DB_ID('x3v6')

ALTER DATABASE x3v6
SET OFFLINE

ALTER DATABASE  x3v6
MODIFY FILE( Name = x3v6_data, FILENAME = 'E:\Elmer\Data\x3v6_data.mdf')
ALTER DATABASE  x3v6
MODIFY FILE( Name = x3v6_log, FILENAME = 'E:\Elmer\Data\x3v6_log.ldf')

ALTER DATABASE x3v6
SET ONLINE

USE master
SELECT name, physical_name
FROM sys.master_files
WHERE database_id = DB_ID('x3v6')
