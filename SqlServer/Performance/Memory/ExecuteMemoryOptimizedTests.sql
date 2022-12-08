-- Perform 10 orders of magnitude
DECLARE @i INT = 1, @order_of_magnitude BIGINT = 1, @loop_msg NVARCHAR(250) = ''
WHILE @i <= 10
BEGIN
	PRINT 'Loop: ' + CAST(@i AS NVARCHAR(20)) + ',		Order Of Magnitude: ' + CAST(@order_of_magnitude AS NVARCHAR(MAX))
	exec uspTestMemoryOptimizedTables @IsOptimized=0, @LoopCount=@order_of_magnitude, @ShowReport=0
	exec uspTestMemoryOptimizedTables @IsOptimized=1, @LoopCount=@order_of_magnitude, @ShowReport=0
	SET @i += 1
	SET @order_of_magnitude = @order_of_magnitude * 10 
END