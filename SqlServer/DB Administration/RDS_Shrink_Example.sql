/*****************************************************************************
* Description:	Test script to demonstrate expanding and contracting
*				a sql database. 
* Author:		Bob Delamater
*****************************************************************************/
SET NOCOUNT ON;

USE master;
GO
--DROP DATABASE IF EXISTS ZTEST1;
IF DB_ID('ZTEST1') IS NOT NULL
BEGIN
	PRINT 'Dropping Database ZTEST1'
	EXECUTE msdb.dbo.rds_drop_database N'ZTEST1'	
END
GO
CREATE DATABASE ZTEST1 ON PRIMARY 
(
	NAME = ZTEST_dat, 
	FILENAME = 'D:\RDSDBDATA\DATA\ZTEST1.mdf',
	SIZE = 10,
	FILEGROWTH = 5%
) LOG ON
(
	NAME = ZTEST_log,
	FILENAME = 'D:\RDSDBDATA\DATA\ZTEST1_log.ldf',
	SIZE = 10,
	FILEGROWTH = 5
)

ALTER DATABASE ZTEST1 SET RECOVERY FULL;

GO
USE ZTEST1
GO

DROP FUNCTION IF EXISTS dbo.ufn_GetDbSize;
GO
CREATE FUNCTION dbo.ufn_GetDbSize(@DBName SYSNAME) 
RETURNS TABLE 
AS 
RETURN
(
	SELECT      d.name,  
				f.size*8/1024 MB  , 
				type_desc
	FROM        sys.databases d
		JOIN        sys.master_files f
			ON          d.database_id=f.database_id  
	WHERE d.name = @DBName
)
GO

DROP TABLE IF EXISTS dbo.t1;
CREATE TABLE dbo.t1(ID INT PRIMARY KEY IDENTITY(1,1), SomeString NVARCHAR(MAX));

DECLARE @i INT
DECLARE @BigString NVARCHAR(MAX), @DBName SYSNAME
SET @BigString = REPLICATE(NEWID(),1000000000)
SET @DBName = 'ZTEST1'

-- Report Database Size
SELECT * FROM dbo.ufn_GetDbSize(@DBName)

SET @i = 0
WhILE @i < 10000
BEGIN
	INSERT INTO dbo.t1(SomeString) VALUES(@BigString)
	SET @i = @i + 1
	IF @i % 1000 = 0
	BEGIN
		-- Report progress on messages tab
		PRINT 'Looping / Record number: ' + CAST(@i AS NVARCHAR(MAX))
	END
END
--SELECT * FROM dbo.t1

-- Report Database Size
SELECT * FROM dbo.ufn_GetDbSize(DB_NAME())

-- Free up space in the database
DROP TABLE dbo.t1;

USE master;
GO

-- Backup Database
/* NOTE TO PAUL: Can't actually do the backup until you give this information, but it should be an example
exec msdb.dbo.rds_backup_database 
        @source_db_name='ZTEST1',
        @s3_arn_to_backup_to='arn:aws:s3:::bucket_name/file_name_and_extension',
        @kms_master_key_arn='arn:aws:kms:region:account-id:key/key-id',
        @overwrite_S3_backup_file=1,
        @type='FULL';
--exec msdb.dbo.rds_backup_database
*/
GO
USE [ZTEST1]
GO
DBCC SHRINKFILE (N'ZTEST_dat' , 10)
GO
USE [ZTEST1]
GO
DBCC SHRINKFILE (N'ZTEST_log' , 10)
GO

-- Shrink Files
-- Determine if you want to shrink the tempdb or not
execute msdb.dbo.rds_shrink_tempdbfile @temp_filename='templog', @target_size=100 -- log file
execute msdb.dbo.rds_shrink_tempdbfile @temp_filename='tempdev', @target_size=100 -- data file / don't use 100, it's too small, just an example
GO
DBCC SHRINKFILE (N'ZTEST_log' , 50)
GO
DBCC SHRINKFILE (N'ZTEST_dat' , 1)
GO
SELECT * FROM dbo.ufn_GetDbSize(DB_NAME())
GO



GO

-- Drop Database


/* Arbitrarily make files bigger, not a valid test for a variety of reasons 
USE [master]
GO
ALTER DATABASE [ZTEST1] MODIFY FILE ( NAME = N'ZTEST_dat', SIZE = 204800KB )
GO
ALTER DATABASE [ZTEST1] MODIFY FILE ( NAME = N'ZTEST_log', SIZE = 204800KB )
GO
*/
