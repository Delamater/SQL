DROP TABLE IF EXISTS #tmp
DECLARE @FastNQueries TABLE(
	ID INT IDENTITY(1,1) PRIMARY KEY NOT NULL,
	query_id INT NOT NULL, 
	query_text_id INT NOT NULL,
	query_sql_text NVARCHAR(MAX),
	statement_sql_handle VARBINARY(MAX) NOT NULL,
	FastPosition INT NOT NULL,
	SelectPosition INT,
	FastValue INT NOT NULL,
	SelectSansFast NVARCHAR(MAX)
)

INSERT INTO @FastNQueries
SELECT
    qsq.query_id,
    qsq.query_text_id,
    qsqt.query_sql_text,
    qsqt.statement_sql_handle,
    CHARINDEX('Option (FAST', qsqt.query_sql_text) + LEN('Option (FAST') AS FastPosition,
	CHARINDEX('SELECT', UPPER(qsqt.query_sql_text),0) SelectPosition,
    SUBSTRING(qsqt.query_sql_text, CHARINDEX('Option (FAST', qsqt.query_sql_text) + LEN('Option (FAST'), 
        CHARINDEX(')', qsqt.query_sql_text, CHARINDEX('Option (FAST', qsqt.query_sql_text)) - (CHARINDEX('Option (FAST', qsqt.query_sql_text) + LEN('Option (FAST'))) AS FastValue,
	''
FROM sys.query_store_query qsq
INNER JOIN sys.query_store_query_text qsqt
    ON qsq.query_text_id = qsqt.query_text_id
WHERE qsqt.query_sql_text LIKE '%FAST%'

UPDATE @FastNQueries
SET SelectSansFast = SUBSTRING(query_sql_text,SelectPosition, FastPosition)
FROM @FastNQueries

-- Give me FAST N queries order by FastValue DESC
SELECT * INTO #tmp FROM @FastNQueries ORDER BY FastValue DESC

-- Give me FAST N queries and find any other queries that have the same text but without the FAST N
WITH cte AS(
SELECT qsq.query_id, qsqt.query_sql_text
FROM sys.query_store_query qsq
	INNER JOIN sys.query_store_query_text qsqt
		ON qsq.query_text_id = qsqt.query_text_id
)
SELECT qsq.query_id, qsqt.query_sql_text, t.query_sql_text
FROM sys.query_store_query qsq
	INNER JOIN sys.query_store_query_text qsqt
		on qsq.query_text_id = qsqt.query_text_id
	LEFT JOIN #tmp t
		ON qsqt.query_sql_text LIKE t.SelectSansFast COLLATE Latin1_General_BIN2
WHERE qsqt.query_sql_text NOT LIKE '%FAST%' AND t.query_sql_text IS NOT NULL