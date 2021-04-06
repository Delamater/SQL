/******************************************************************************
* Description:      Create clustered index which allows duplicates, but fails
*                   to allow entry at some point. Essentially, we are 
*                   exposing the uniquifier's limitations. 
* Warning:			Make sure you have ~75 GB of disk space available
******************************************************************************/

CREATE DATABASE dbDupeClusteredIndex
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'dbDupeClusteredIndex', FILENAME = N'W:\data\dbtest.mdf' , SIZE = 1024KB, FILEGROWTH = 65536KB )
 LOG ON 
( NAME = N'dbDupeClusteredIndex_log', FILENAME = N'W:\data\dbtest_log.ldf' , SIZE = 1024KB , FILEGROWTH = 65536KB )

GO
USE dbDupeClusteredIndex
GO

SET NOCOUNT ON
-- Expected to insert 1,054,977,832 rows
SELECT CAST(1 AS BIT) as DuplicateValueColumn
INTO dbo.Duplicates
FROM sys.columns a
    CROSS JOIN sys.columns b
    CROSS JOIN sys.columns c;
-- Report insertion count
SELECT @@rowcount

--ALTER TABLE [dbo].[Duplicates] REBUILD PARTITION = ALL
--WITH (DATA_COMPRESSION = ROW)


-- Create clustered index
CREATE CLUSTERED INDEX clsDuplicates ON dbo.Duplicates(DuplicateValueColumn);
-- CREATE NONCLUSTERED INDEX clsDuplicates ON dbo.Duplicates(DuplicateValueColumn);
GO

DECLARE @i INT, @iCount BIGINT, @msg NVARCHAR(MAX)
WHILE 1=1 
BEGIN
    BEGIN TRY
        INSERT INTO dbo.Duplicates(DuplicateValueColumn)
        SELECT TOP 2000000 CAST(1 AS BIT) 
        FROM sys.columns a
            CROSS JOIN sys.columns b
            CROSS JOIN (SELECT TOP 23 column_id from sys.columns) c;
		SET @iCount = (
			SELECT
			   Total_Rows= SUM(st.row_count)
			FROM
			   sys.dm_db_partition_stats st
			WHERE
				object_name(object_id) = 'Duplicates' AND (index_id < 2)	
				AND OBJECT_SCHEMA_NAME(object_id) = 'dbo'		
		)
		SET @msg = (SELECT FORMATMESSAGE('Total rows: %I64d - | %s', @iCount,(SELECT CAST(SYSUTCDATETIME() AS NVARCHAR(MAX)))))
		RAISERROR(@msg, 0, 1) WITH NOWAIT

		-- Cancel the query easier if needed
		CHECKPOINT 20 

    END TRY
    BEGIN CATCH
        SELECT
            ERROR_NUMBER() AS ErrorNumber,
            ERROR_STATE() AS ErrorState,
            ERROR_SEVERITY() AS ErrorSeverity,
            ERROR_PROCEDURE() AS ErrorProcedure,
            ERROR_LINE() AS ErrorLine,
            ERROR_MESSAGE() AS ErrorMessage;

			BREAK
    END CATCH

END


/*
GO
USE master
GO
DROP DATABASE dbDupeClusteredIndex;
DROP TABLE dbo.Duplicates
GO
*/

