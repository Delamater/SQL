-- =============================================
-- Create Database Snapshot Template
-- =============================================
USE master
GO

-- Drop database snapshot if it already exists
IF  EXISTS (
	SELECT name 
		FROM sys.databases 
		WHERE name = N'x3v7_01'
)
DROP DATABASE x3v7_01
GO

-- Create the database snapshot
CREATE DATABASE x3v7_125PM ON
( NAME = x3v7_data, FILENAME = 
'E:\Sage\SAGEX3V7\X3V7SQL\database\data\x3v7_01.ss' )
AS SNAPSHOT OF x3v7;
GO