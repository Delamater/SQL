-- Read Any Profiler Trace When Saved As A Trace File
-- Press Ctrl + Shift + M to replace the template parameters
DECLARE @filPath VARCHAR(255)
SET @filPath = '<File Path, VARCHAR(255), C:\temp\mytrace.trc>'

SELECT IDENTITY(int, 1, 1) AS RowNumber, *
FROM fn_trace_gettable(@filPath, DEFAULT)
