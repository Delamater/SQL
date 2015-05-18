-- Move SQL data files to another drive
USE master
SELECT name, physical_name
FROM sys.master_files
WHERE name LIKE 'x3v6%'

ALTER DATABASE x3v6
SET OFFLINE

ALTER DATABASE x3v6
MODIFY FILE( NAME = x3v6_data, FILENAME = 'E:\MyNewX3Folder\DataFiles\x3v6_data.mdf')

GO

ALTER DATABASE x3v6
MODIFY FILE( NAME = x3v6_log, FILENAME = 'E:\MyNewX3Folder\DataFiles\x3v6_log.ldf')

-- You need to move the files manually here

-- Now set the database online, after you've moved the files on disk
ALTER DATABASE x3v6
SET ONLINE

GO

USE master
SELECT name, physical_name
FROM sys.master_files
WHERE name LIKE 'x3v6%'
