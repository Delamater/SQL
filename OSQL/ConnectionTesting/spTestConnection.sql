IF OBJECT_ID('dbo.spTestConnection') IS NOT NULL
BEGIN
	PRINT 'Recreating stored procedure dbo.spTestConnection'
	DROP PROCEDURE dbo.spTestConnection 
END
GO

CREATE PROCEDURE dbo.spTestConnection AS

IF OBJECT_ID('dbo.ConnectionTest') IS NULL
BEGIN
	CREATE TABLE dbo.ConnectionTest
	(
		ID				INT	IDENTITY(1,1),
		TestTime		DATETIME
	)
END

INSERT INTO dbo.ConnectionTest(TestTime) VALUES(GETDATE())
