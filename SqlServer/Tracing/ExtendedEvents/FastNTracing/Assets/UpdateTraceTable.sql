-- Reset data
IF COL_LENGTH('dbo.FastNone', 'SelectPosition') IS NOT NULL ALTER TABLE dbo.FastNone DROP COLUMN SelectPosition;
IF COL_LENGTH('dbo.FastNone', 'WherePosition') IS NOT NULL ALTER TABLE dbo.FastNone DROP COLUMN WherePosition;
IF COL_LENGTH('dbo.FastNone', 'OrderByPosition') IS NOT NULL ALTER TABLE dbo.FastNone DROP COLUMN OrderByPosition;
IF COL_LENGTH('dbo.FastNone', 'SelectList') IS NOT NULL ALTER TABLE dbo.FastNone DROP COLUMN SelectList;
IF COL_LENGTH('dbo.FastNone', 'WhereClause') IS NOT NULL ALTER TABLE dbo.FastNone DROP COLUMN WhereClause;
IF COL_LENGTH('dbo.FastNone', 'OrderByClause') IS NOT NULL ALTER TABLE dbo.FastNone DROP COLUMN OrderByClause;


-- Add columns we need for analysis
ALTER TABLE dbo.FastNone ADD SelectPosition INT
ALTER TABLE dbo.FastNone ADD WherePosition INT
ALTER TABLE dbo.FastNone ADD OrderByPosition INT
ALTER TABLE dbo.FastNone ADD SelectList NVARCHAR(MAX)
ALTER TABLE dbo.FastNone ADD WhereClause NVARCHAR(MAX)
ALTER TABLE dbo.FastNone ADD OrderByClause NVARCHAR(MAX)



BEGIN TRY
	BEGIN TRAN

	-- Get some meta data about the position of key statement constructs
	UPDATE dbo.FastNone
	SET SelectPosition = CHARINDEX('select', lower([statement])),
		WherePosition = CHARINDEX('where', lower([statement])),
		OrderByPosition = CHARINDEX('order by', lower([statement]))
	FROM dbo.FastNone
	
	-- SET SelectList
	UPDATE dbo.FastNone
	SET SelectList = SUBSTRING(statement, SelectPosition, WherePosition)
	FROM dbo.FastNone
	WHERE SelectPosition > 0 AND WherePosition > 0 

	-- SET SelectList without WhereClause
	UPDATE dbo.FastNone
	SET SelectList = SUBSTRING(statement, SelectPosition, LEN(statement))
	FROM dbo.FastNone
	WHERE SelectPosition > 0 AND WherePosition = 0 AND SelectList IS NULL 

	-- SET where clause
	UPDATE dbo.FastNone
	SET 
		WhereClause = SUBSTRING(statement, WherePosition, OrderByPosition)
	FROM dbo.FastNone
	WHERE WherePosition > 0 AND OrderByPosition > 0

	-- SET WhereClause without OrderBy
	UPDATE dbo.FastNone
	SET 
		WhereClause = SUBSTRING(statement, WherePosition, LEN(statement))
	FROM dbo.FastNone
	WHERE WherePosition > 0 AND OrderByPosition = 0 AND WhereClause IS NULL

	-- Update order by clause 
	UPDATE dbo.FastNone
	SET 
		OrderByClause = SUBSTRING(statement, OrderByPosition, LEN(statement))
	FROM dbo.FastNone
	WHERE OrderByPosition > 0	

	IF EXISTS(
		SELECT 1
			--statement, SelectPosition, WherePosition, OrderByPosition, name, SelectList, WhereClause, OrderByClause
		FROM dbo.FastNone
		WHERE 
			(SelectPosition > 0 AND SelectList IS NULL) OR
			(WherePosition > 0 AND WhereClause IS NULL) OR
			(OrderByPosition > 0 AND OrderByClause IS NULL)
	)
	BEGIN
		THROW 51000, 'Not all of the statements were parsed properly during the statement parsing phase', 1
	END
END TRY
BEGIN CATCH
	SELECT ERROR_LINE(), ERROR_NUMBER(), ERROR_MESSAGE(), ERROR_PROCEDURE(), ERROR_SEVERITY(), ERROR_STATE()
	ROLLBACK
END CATCH


DROP VIEW IF EXISTS dbo.vFastNone
GO
CREATE VIEW dbo.vFastNone AS
SELECT        name, timestamp, username, session_id, database_id, duration, options, options_text, database_name, client_app_name, client_hostname, cpu_time, nt_username, physical_reads, logical_reads, writes, spills, 
                         row_count, result, application_name, plan_handle, object_name, estimated_rows, estimated_cost, requested_memory_kb, used_memory_kb, ideal_memory_kb, granted_memory_kb, dop, last_row_count, statement, 
                         error_number, message, statement_handle, SelectPosition, WherePosition, OrderByPosition, SelectList, WhereClause, OrderByClause
FROM            FastNone
WHERE        (SelectPosition > 0)

GO

SELECT statement, SelectList, WhereClause, OrderByClause
FROM dbo.vFastNone
WHERE len(statement) > 0