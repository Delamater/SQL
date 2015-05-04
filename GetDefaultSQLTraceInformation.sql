-- Query the default profiler trace for information
DECLARE @path VARCHAR(MAX) 
SET @path = (SELECT [path] FROM sys.traces WHERE id = 1 )

SELECT * 
from sys.fn_trace_gettable(@path, DEFAULT)
WHERE HostName = 'MyHostNameHere' 
ORDER BY StartTime DESC
