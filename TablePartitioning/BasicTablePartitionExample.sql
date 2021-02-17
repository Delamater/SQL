SET NOCOUNT ON
IF NOT EXISTS(SELECT name FROM sys.databases WHERE name = 't2')
BEGIN
	SELECT FORMATMESSAGE('Creating database %s', 't2')
	CREATE DATABASE t2

	-- Create secondary filegroup
	SELECT FORMATMESSAGE('Creating filegroup %s', 'FG2')
	ALTER DATABASE [t2] ADD FILEGROUP [FG2]
	ALTER DATABASE [t2] ADD FILEGROUP [FG3]

	-- Create files
	SELECT FORMATMESSAGE('Creating files: %s, %s', 'FG2.ndf', 'FG2_log.ldf')
	ALTER DATABASE [t2] ADD FILE ( NAME = N'FG2a', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL15.SQL2019\MSSQL\DATA\FG2a.ndf' , SIZE = 8192KB , FILEGROWTH = 65536KB ) TO FILEGROUP [FG2]
	ALTER DATABASE [t2] ADD LOG FILE ( NAME = N'FG2_log', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL15.SQL2019\MSSQL\DATA\FG2_log.ldf' , SIZE = 8192KB , FILEGROWTH = 65536KB )

	ALTER DATABASE [t2] ADD FILE ( NAME = N'FG3a', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL15.SQL2019\MSSQL\DATA\FG3a.ndf' , SIZE = 8192KB , FILEGROWTH = 65536KB ) TO FILEGROUP [FG3]
	ALTER DATABASE [t2] ADD LOG FILE ( NAME = N'FG3_log', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL15.SQL2019\MSSQL\DATA\FG3_log.ldf' , SIZE = 8192KB , FILEGROWTH = 65536KB )

END

GO
USE t2
GO

-- Create Partition Range and Scheme
CREATE PARTITION FUNCTION F_PART_IDENT(NVARCHAR(2)) AS RANGE LEFT FOR VALUES('B');
CREATE PARTITION SCHEME S_PART_IDENT AS PARTITION F_PART_IDENT ALL TO (FG3)

-- Create sample table (NO CLUSTERED INDEX ON PURPOSE)
CREATE TABLE dbo.t1(ID INT, FNAME NVARCHAR(MAX), Identifier NVARCHAR(2), BigExpensiveColumn NVARCHAR(MAX)) ON S_PART_IDENT(Identifier)

-- Sequences
CREATE SEQUENCE dbo.t1_SEQ 
	START WITH 1
	INCREMENT BY 1
	MINVALUE 1
	CYCLE



-- INSERT Demo Data
-- Next Value | Random String | Random string from either 'A', 'B', or 'C'
INSERT INTO dbo.t1(ID, FNAME, Identifier, BigExpensiveColumn)
VALUES(NEXT VALUE FOR dbo.t1_SEQ, LEFT(NEWID(),20), UPPER(CHAR((rand()*3+65))), REPLICATE('ABC',1000))
GO 10000

-- Check data output
SELECT *
FROM dbo.t1

-- Check data files
SELECT 
*
FROM sys.partitions p
	JOIN sys.destination_data_spaces dds 
		ON p.partition_number = dds.destination_id
	JOIN sys.filegroups f 
		ON dds.data_space_id = f.data_space_id
WHERE OBJECT_NAME(OBJECT_ID) = 't1'


-- Drop database
USE MASTER
SELECT FORMATMESSAGE('Dropping database %s', 't2')
DROP DATABASE t2
