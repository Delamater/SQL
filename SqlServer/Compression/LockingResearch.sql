-- To compress or not to compress, that is the question
--CREATE SCHEMA TEST
set nocount on
IF OBJECT_ID('TEST.t1') IS NOT NULL
BEGIN
	PRINT 'Dropping dbo.t1'
	DROP TABLE TEST.t1
END

create table TEST.t1
(
	ID INT PRIMARY KEY IDENTITY(1,1),
	NUM1 INT,
	Dec1 DECIMAL(30,10),
	String VARCHAR(600),
	String2 VARCHAR(1000)
)
--ALTER TABLE TEST.t1 REBUILD PARTITION = ALL WITH (DATA_COMPRESSION = PAGE)
--create index ix1 on TEST.t1(NUM1)
--create index ix2 on TEST.t1(Dec1)
--create index ix3 on TEST.t1(String)
--create index ix4 on TEST.t1(String2)
create index ix1 ON TEST.t1(ID, NUM1, Dec1, String, String2)

declare @i int
set @i = 0
while @i < 100
begin
	INSERT INTO TEST.t1(NUM1, Dec1 , String, String2) 
	VALUES
		(
			1, 
			RAND()*10000,
			--REPLICATE(CAST(NEWID() AS VARCHAR(300)),10),
			space(600),
			' '
		)
	set @i+=1
end

--select * from dbo.t1

select 
object_name(object_id) as 'tablename',
count(*) as 'totalpages',
sum(Case when is_allocated=0 then 1 else 0 end) as 'unusedPages',
sum(Case when is_allocated=1 then 1 else 0 end) as 'usedPages'
from sys.dm_db_database_page_allocations(db_id(),object_id('TEST.t1'),null,null,'DETAILED')
group by object_name(object_id)


--exec sys.sp_estimate_data_compression_savings  'TEST', 't1',NULL,1,'NONE'
--exec sys.sp_estimate_data_compression_savings  'TEST', 't1',NULL,1,'ROW'
--exec sys.sp_estimate_data_compression_savings  'TEST', 't1',NULL,1,'PAGE'

delete dbo.CompressionFacts where schema_name = 'TEST'
exec uspDataCompression @CompressionType = 'ROW', @Compress = 0, @SchemaName = 'TEST';
exec uspDataCompression @CompressionType = 'PAGE', @Compress = 0, @SchemaName = 'TEST';

WITH cte(schemaName, objectName, CompressionType, SumOfCurrentCompressionSetting_MB, SumWithRequestedCompressionSetting_MB, Savings_MB) AS
(
	SELECT [schema_name], [object_name], [Compression_Type],
		(SUM(CAST([size_with_current_compression_setting_KB] AS DECIMAL(18,3)))) / 1024 SumOfCurrentCompressionSetting_MB,
		(SUM(CAST([size_with_requested_compression_setting_KB] AS DECIMAL(18,3)))) / 1024 SumWithRequestedCompressionSetting_MB,
		(SUM(CAST([size_with_current_compression_setting_KB] AS DECIMAL(18,3))) - SUM(CAST([size_with_requested_compression_setting_KB] AS DECIMAL(18,3)))) / 1024 Savings_MB
	FROM dbo.CompressionFacts
	--WHERE [schema_name] = 'X3PERF'
	GROUP BY [schema_name], [object_name], [Compression_Type]
	--ORDER BY [schema_name], [object_name], [Compression_Type]
)
SELECT 
	*
FROM cte WHERE schemaName = 'TEST'


IF OBJECT_ID('tempdb..#ind') IS NOT NULL
BEGIN
	PRINT 'Dropping table #ind'
	DROP TABLE #ind
END
CREATE TABLE #ind
(
	PageFID INT,
	PagePID INT,
	IAMFID INT,
	IAMPID INT,
	ObjectID INT,
	IndexID SMALLINT,
	PartitionNumber TinyInt,
	PartitionID BIGINT,
	iam_chain_type VARCHAR(250),
	PageType INT,
	IndexLevel INT,
	NextPageFID INT,
	NextPagePID INT,
	PrevPageFID INT,
	PrevPagePID INT
)
INSERT INTO #ind EXEC('DBCC IND(5,''TEST.t1'',-1)')

-- DBCC IND(5,'TEST.t1',-1)

IF OBJECT_ID('tempdb..#page') IS NOT NULL
BEGIN
	PRINT 'Dropping table #page'
	DROP TABLE #page
END
CREATE TABLE #page
(
	ParentObject VARCHAR(250),
	Object VARCHAR(250),
	Field VARCHAR(250),
	VALUE VARCHAR(MAX)
)

---- Figure out a good page to look at
--DECLARE @PageFID INT, @PagePID INT
--SELECT @PageFID = PageFID, @PagePID = PagePID
--FROM #ind
--WHERE PageType = 1 AND IndexID = 1 AND NextPagePID > 0
--ORDER BY PagePID ASC
--INSERT INTO #page(ParentObject,Object, Field, VALUE) EXEC ('DBCC PAGE(''sagex3'','+ @PageFID +','+ @PagePID +',3) WITH TABLERESULTS')



--SELECT * 
--FROM #page 
----WHERE Field IN('ID', 'NUM1', 'Dec1', 'String', 'String2')
--SELECT @PagePID AS PagePID, * 
--FROM #page 
--WHERE Field IN('ID') ORDER BY Field, VALUE



DECLARE @min INT, @max INT, @next INT
-- Figure out a good page to look at
SELECT @min = MIN(PagePID), @max = MAX(PagePID)FROM #ind where PageType = 1
SET @next = @min

WHILE @next <> 0
BEGIN
	-- Insert INTO #page
	INSERT INTO #page(ParentObject,Object, Field, VALUE) EXEC ('DBCC PAGE(''sagex3'',1,'+ @next +',3) WITH TABLERESULTS')
	-- Get next page
	SELECT @next = NextPagePID
	FROM #ind WHERE PagePID = @next
END

--SELECT * FROM #ind WHERE NextPagePID > 0 AND IndexID = 1 AND PageType = 1 ORDER BY PagePID ASC

--DBCC PAGE('sagex3', 1, 13827112,3) WITH TABLERESULTS
--SELECT * 
--FROM #page 
--WHERE Field IN('ID') ORDER BY Field, VALUE


select * from #ind where IndexID = 2

select * from #page WHERE Field IN('ID') ORDER BY VALUE
