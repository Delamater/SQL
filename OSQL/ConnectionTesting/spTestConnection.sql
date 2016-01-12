USE [TestDB]
GO
/****** Object:  StoredProcedure [dbo].[spTestConnection]    Script Date: 1/12/2016 12:29:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[spTestConnection] AS

IF OBJECT_ID('dbo.ConnectionTest') IS NULL
BEGIN
	CREATE TABLE dbo.ConnectionTest
	(
		ID				INT	IDENTITY(1,1),
		TestTime		DATETIME
	)
END

INSERT INTO dbo.ConnectionTest(TestTime) VALUES(GETDATE())
SELECT TOP 1 * FROM dbo.ConnectionTest ORDER BY ID DESC
