-- Locate Truncate Table User
SELECT [Transaction Name], SUSER_SNAME([Transaction SID]) As UserName, [Begin Time], Operation, [Transaction ID], Description 
FROM fn_dblog(null, null) 
WHERE LOWER([Transaction Name]) like LOWER('%truncate%')
