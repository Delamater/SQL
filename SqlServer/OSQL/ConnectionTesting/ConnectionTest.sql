WHILE 1=1
BEGIN
	WAITFOR DELAY '00:00:01'
	exec dbo.spTestConnection 	
END


