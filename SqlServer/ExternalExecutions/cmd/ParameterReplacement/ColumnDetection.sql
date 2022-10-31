-- Create log in current directory called MyLogFile.txt which will contain
-- all the output of this script, including any print statements.
:OUT $(LogFileName)

-- CREATE DATABASE zTest01
USE zTest01
-- CREATE TABLE TestTable(ID int, FirstName NVARCHAR(100), LastName NVARCHAR(100))

-- Test the presence of a column named SocialSecurity
SELECT COL_LENGTH('dbo.TestTable',$(column_name))