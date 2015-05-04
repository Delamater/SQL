-- Query SQL Server's default log file
-- Do yourself a favor and put some filters on this query for your production server
SELECT top 1000 [Transaction Name], SUSER_SNAME([Transaction SID]) As UserName, [Begin Time], Operation, [Transaction ID], Description 
FROM fn_dblog(null, null) 
ORDER BY [Begin Time] DESC
