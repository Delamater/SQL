IF OBJECT_ID('tempdb..#spaceused') IS NOT NULL
BEGIN
	DROP TABLE #spaceused
END
CREATE TABLE #spaceused
(
	name SYSNAME,
	rows INT,
	reserved VARCHAR(100),
	data VARCHAR(100),
	index_size VARCHAR(100),
	unused VARCHAR(100)
)
INSERT #spaceused EXEC sp_spaceused 'X3PERF.SORDERQ'

UPDATE #spaceused
SET reserved = LTRIM(RTRIM(REPLACE(reserved,'KB',''))),
	data = LTRIM(RTRIM(REPLACE(data,'KB',''))),
	index_size = LTRIM(RTRIM(REPLACE(index_size,'KB',''))),
	unused = LTRIM(RTRIM(REPLACE(unused,'KB','')))

ALTER TABLE #spaceused ADD data_MB INT
ALTER TABLE #spaceused ADD index_size_MB INT

UPDATE #spaceused
SET data_MB = data / 1024, index_size_MB = index_size / 1024

SELECT * FROM #spaceused

DROP TABLE #spaceused
