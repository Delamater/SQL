IF OBJECT_ID('X3.tsmIndexDefrag', 'U') IS NULL
BEGIN
	CREATE TABLE [X3].[tsmIndexDefrag](
		[IndexDefragKey] [INT] IDENTITY(1,1) NOT NULL,
		[AllocUnitTypeDesc] [VARCHAR](64) NULL,
		[AvgFragInPer] [FLOAT] NULL,
		[AvgFragSizeInPages] [FLOAT] NULL,
		[AvgPageSpaceUsedInPer] [FLOAT] NULL,
		[AvgRecordSizeInBytes] [FLOAT] NULL,
		[BatchID] [INT] NULL,
		[Command] [VARCHAR](6000) NULL,
		[CreatedDate] [SMALLDATETIME] NULL,
		[DatabaseID] [SMALLINT] NULL,
		[DatabaseName] [VARCHAR](100) NULL,
		[ForwardedRecordCount] [INT] NULL,
		[FragCount] [INT] NULL,
		[GhostRecordCount] [INT] NULL,
		[IndexDepth] [TINYINT] NULL,
		[IndexID] [INT] NULL,
		[IndexLevel] [TINYINT] NULL,
		[IndexTypeDesc] [VARCHAR](64) NULL,
		[IsDefragged] [SMALLINT] NULL,
		[MaxRecordSizeInBytes] [INT] NULL,
		[MinRecordSizeInBytes] [INT] NULL,
		[ObjectID] [INT] NULL,
		[ObjectName] [VARCHAR](100) NULL,
		[PageCount] [INT] NULL,
		[PartitionNo] [INT] NULL,
		[RecordCount] [INT] NULL,
		[VersionGhostRecordCount] [INT] NULL,
	PRIMARY KEY CLUSTERED 
	(
		[IndexDefragKey] ASC
	)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
	) ON [PRIMARY]

	ALTER TABLE [X3].[tsmIndexDefrag] ADD  DEFAULT ((0)) FOR [AvgFragInPer]
	ALTER TABLE [X3].[tsmIndexDefrag] ADD  DEFAULT ((0)) FOR [AvgFragSizeInPages]
	ALTER TABLE [X3].[tsmIndexDefrag] ADD  DEFAULT ((0)) FOR [AvgPageSpaceUsedInPer]
	ALTER TABLE [X3].[tsmIndexDefrag] ADD  DEFAULT ((0)) FOR [AvgRecordSizeInBytes]

END

IF OBJECT_ID('X3.tsmIndexDefragQueue', 'U') IS NULL

BEGIN
	CREATE TABLE [X3].[tsmIndexDefragQueue](
		[IndexDefragQueueKey] [INT] IDENTITY(1,1) NOT NULL,
		[Command] [VARCHAR](6000) NULL,
		[CreatedDate] [SMALLDATETIME] NULL,
		[IndexDefragKey] [INT] NULL,
	PRIMARY KEY CLUSTERED 
	(
		[IndexDefragQueueKey] ASC
	)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
	) ON [PRIMARY]
END
GO




--********************************************************************************************* 
-- spIndexDefrag - Procedure to defragment the index for given input parameters. It is called
-- from user defined scheduled job or can be called from SQL Server Management Studio.
--
-- Copyright (c) 1995-2009 Sage Software, Inc. All Rights Reserved.
--
-- ********************************************************************************************
/***************************************************************************************************
Sample Exec:

--when @_Debug = 1, we just print out commands we will run
Exec [X3].spIndexDefrag
       @_PageCount = 100,
       @_AvgFragInPer = 10,
       @_Debug = 1

--when @_Debug = 0, we run for real
Exec [X3].spIndexDefrag
       @_PageCount = 100,
       @_AvgFragInPer = 10,
       @_Debug = 0

select * from tsmIndexDefrag
select * from tsmIndexDefragQueue

****************************************************************************************************/

IF EXISTS (SELECT 1 FROM sys.objects WHERE object_id = object_id ( N'[X3].spIndexDefrag') and Type = 'P')
BEGIN
	DROP PROCEDURE [X3].spIndexDefrag
END
GO

CREATE PROCEDURE [X3].spIndexDefrag
(
@_PageCount INT = 100,
@_AvgFragInPer FLOAT = 10,
@_Debug BIT = 0
)
AS
SET NOCOUNT ON;
DECLARE @_ObjectID INT;
DECLARE @_IndexID INT;
DECLARE @_PartitionCount INT;
DECLARE @_SchemaName VARCHAR(130); 
DECLARE @_ObjectName VARCHAR(130); 
DECLARE @_IndexName VARCHAR(130); 
DECLARE @_PartitionNo INT;
DECLARE @_Partitions INT;
DECLARE @_Frag FLOAT;
DECLARE @_SQLCommand VARCHAR(4000); 
DECLARE @_CreatedDate SMALLDATETIME
DECLARE @_Min INT
DECLARE @_Max INT
DECLARE @_BatchID INT
DECLARE @_KeyCounter INT
DECLARE @_IsDefragged BIT
DECLARE @_IsEnterpriseVersion INT
DECLARE @_HasBlobData INT
DECLARE @_IndexDefragKey INT
DECLARE @_TableInfo TABLE
(
	TableName VARCHAR(128),
	ColumnName VARCHAR(128),
	ColumnDataType VARCHAR(128),
	MaxLength INT
)

IF OBJECT_ID('dbo.tsmIndexDefrag', 'U') IS NULL
BEGIN
	PRINT 'Table dbo.tsmIndexDefrag is missing. The stored procedure stopped.'
	RETURN 0
END

SELECT @_CreatedDate = GetDate()

--******************************************************************************
--Get SQL SERVER edition, if enterprise then we can do ONLINE index operation.
--******************************************************************************

SELECT @_IsEnterpriseVersion = CHARINDEX('ENTERPRISE', CAST(SERVERPROPERTY ('EDITION') AS VARCHAR))
SELECT @_BatchID = COALESCE(MAX(BatchID) + 1,1) 
FROM [X3].tsmIndexDefrag WITH (NOLOCK)


--Clear out Queue table and reseed identity
DELETE tsmIndexDefragQueue
DBCC CHECKIDENT ('tsmIndexDefragQueue', RESEED, 1);

--*************************************************************************************************
--If we already have some work still left over, go finish those instead of getting new work order
--*************************************************************************************************
IF NOT EXISTS(SELECT 1 FROM [X3].tsmIndexDefrag WITH (NOLOCK) WHERE IsDefragged = 0)
BEGIN
	INSERT INTO [X3].tsmIndexDefrag
       (
       BatchID,CreatedDate,DatabaseID,DatabaseName,ObjectID,ObjectName,PartitionNo,IndexID,IndexTypeDesc,
       AllocUnitTypeDesc,IndexDepth,IndexLevel,AvgFragInPer,FragCount,AvgFragSizeInPages,
       PageCount,AvgPageSpaceUsedInPer,RecordCount,GhostRecordCount,VersionGhostRecordCount,
       MinRecordSizeInBytes,MaxRecordSizeInBytes,AvgRecordSizeInBytes,ForwardedRecordCount,
		IsDefragged	
       )
	SELECT
       @_BatchID,@_CreatedDate,Database_ID,
       CONVERT(VARCHAR(35),DB_NAME(database_id)) AS DatabaseName,
       Object_ID,CONVERT(VARCHAR(35),OBJECT_NAME(OBJECT_ID)) AS 'OBJECT NAME',
       Partition_Number,Index_ID,Index_Type_Desc,
       Alloc_Unit_Type_Desc,Index_Depth,Index_Level,Avg_Fragmentation_In_Percent,Fragment_Count,Avg_Fragment_Size_In_Pages,
       Page_Count,Avg_Page_Space_Used_In_Percent,Record_Count,Ghost_Record_Count,Version_Ghost_Record_Count,
       Min_Record_Size_In_Bytes,Max_Record_Size_In_Bytes,Avg_Record_Size_In_Bytes,Forwarded_Record_Count,
		0
	FROM sys.dm_db_index_physical_stats (DB_ID(), NULL, NULL, NULL, 'DETAILED') 
	WHERE page_count > @_PageCount 
       AND avg_fragmentation_in_percent > @_AvgFragInPer
       AND Index_ID > 0
       ORDER BY Index_Type_Desc, page_count desc, avg_fragmentation_in_percent desc
END
ELSE
BEGIN
       SELECT TOP 1 @_BatchID = BatchID FROM [X3].tsmIndexDefrag WITH (NOLOCK) WHERE IsDefragged = 0
END

--****************************************************
--Build the SQL commands to execute
--****************************************************
SELECT @_Min = MIN(IndexDefragKey), @_Max = MAX(IndexDefragKey) FROM [X3].tsmIndexDefrag WITH (NOLOCK) WHERE BatchID = @_BatchID AND IsDefragged = 0
WHILE (@_Min <= @_Max)
BEGIN
       SELECT		 @_ObjectID = ObjectID,
                     @_IndexID = IndexID,
                     @_PartitionNo = PartitionNo,
                     @_Frag = AvgFragInPer,
                     @_IsDefragged = IsDefragged,
					 @_IndexDefragKey = IndexDefragKey
       FROM [X3].tsmIndexDefrag WITH (NOLOCK)
       WHERE IndexDefragKey = @_Min
       AND BatchID = @_BatchID

       --if we already worked on this index then move on to the next one
       IF (@_IsDefragged = 0)
       BEGIN
			SELECT @_ObjectName = QUOTENAME(o.name), @_SchemaName = QUOTENAME(s.name)
			FROM sys.objects AS o
			JOIN sys.schemas as s ON s.schema_id = o.schema_id
			WHERE o.object_id = @_ObjectID;
			SELECT @_IndexName = QUOTENAME(name)
			FROM sys.indexes
			WHERE  object_id = @_ObjectID AND index_id = @_IndexID;
			SELECT @_PartitionCount = count (*)
			FROM sys.partitions
			WHERE object_id = @_ObjectID AND index_id = @_IndexID;

			--******************************************************
			--if we have blob data, we cannot do rebuild ONLINE
			--******************************************************
			INSERT INTO @_TableInfo(TableName,ColumnName,ColumnDataType,MaxLength)
			SELECT	o.name as TableName
					,c.name as ColumnName
					,t.name as ColumnDataType
					,c.max_length		
			FROM sys.objects o WITH (NOLOCK)
			INNER JOIN sys.columns c WITH (NOLOCK) ON c.object_id = o.object_id
			INNER JOIN sys.types t WITH (NOLOCK) ON t.system_type_id = c.system_type_id
			WHERE o.object_id= @_ObjectID 
			AND t.name in('image', 'text', 'ntext', 'xml', 'varchar', 'nvarchar', 'varbinary')

			SET @_HasBlobData = 0
			
			IF EXISTS(SELECT 1 FROM @_TableInfo WHERE ColumnDataType IN('image','text','ntext','xml'))
			BEGIN
				SET @_HasBlobData = 1
			END
			ELSE
			BEGIN
				IF EXISTS(SELECT 1 FROM @_TableInfo WHERE ColumnDataType IN('varchar','nvarchar','varbinary'))
				BEGIN
					IF EXISTS(SELECT 1 FROM @_TableInfo WHERE MaxLength = 8000 or MaxLength = -1)
					BEGIN
						SET @_HasBlobData = 1
					END							
				END		
			END
			-----------------------------------

			IF (@_Frag < @_AvgFragInPer)
			BEGIN
				SET @_SQLCommand = N'ALTER INDEX ' + @_IndexName + N' ON ' + @_SchemaName + N'.' + @_ObjectName + N' REORGANIZE'
			END
			IF (@_Frag >= @_AvgFragInPer)
			BEGIN
				IF (@_IsEnterpriseVersion = 1) AND (@_HasBlobData = 0)
				BEGIN
					SET @_SQLCommand = N'ALTER INDEX ' + @_IndexName + N' ON ' + @_SchemaName + N'.' + @_ObjectName + N' REBUILD WITH (ONLINE = ON)' 
				END
				ELSE
				BEGIN
					SET @_SQLCommand = N'ALTER INDEX ' + @_IndexName + N' ON ' + @_SchemaName + N'.' + @_ObjectName + N' REBUILD'
				END
			END
			IF (@_PartitionCount > 1)
			BEGIN
				SET @_SQLCommand = @_SQLCommand + N' PARTITION=' + CAST(@_PartitionNo AS VARCHAR(10))
			END

		INSERT INTO tsmIndexDefragQueue(IndexDefragKey,Command) SELECT @_IndexDefragKey,@_SQLCommand

       END

       SELECT @_Min = @_Min + 1
END

--********************************************************
--Update tsmIndexDefrag with the commands in the Queue
--********************************************************
UPDATE tsmIndexDefrag
SET Command = B.Command
FROM tsmIndexDefrag A
INNER JOIN tsmIndexDefragQueue B
ON A.IndexDefragKey = B.IndexDefragKey

--********************************************************
--if we are just debugging, then print all the commands
--********************************************************
IF (@_Debug = 1)
BEGIN
	SELECT * FROM tsmIndexDefragQueue
END
--************************************************************************
--if we are not debugging, then loop through to execute all commands
--we select each command and execute just in case user wants to intercept 
-- and delete the queue so the job can stop.
--************************************************************************
ELSE
BEGIN
	SELECT @_KeyCounter = MIN(IndexDefragQueueKey), @_Max = MAX(IndexDefragQueueKey) FROM dbo.tsmIndexDefragQueue WITH (NOLOCK)
	
	WHILE (@_KeyCounter <= @_Max)
	BEGIN
		SELECT @_IndexDefragKey = IndexDefragKey, @_SQLCommand = Command 
		FROM dbo.tsmIndexDefragQueue WITH (NOLOCK) 
		WHERE IndexDefragQueueKey = @_KeyCounter

		IF (ISNULL(@_SQLCommand,'') <> '')
		BEGIN
			EXEC (@_SQLCommand)
		
			IF (@@ERROR = 0)
			BEGIN
				--******************************************
				--indicate we already worked on this index
				--******************************************
				UPDATE [X3].tsmIndexDefrag
				SET IsDefragged = 1
				WHERE IndexDefragKey = @_IndexDefragKey

				DELETE tsmIndexDefragQueue WHERE IndexDefragQueueKey = @_KeyCounter				
			END
		END

		SET @_KeyCounter = @_KeyCounter + 1
	END
END

GO

