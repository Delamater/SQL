DECLARE @columnName SYSNAME, @tableName SYSNAME, @sql VARCHAR(MAX)

BEGIN TRAN

	BEGIN TRY

		DECLARE mycur CURSOR
		FOR

		SELECT t.name, c.name
		FROM sys.tables t
			INNER JOIN sys.columns c
				ON t.object_id = c.object_id
			INNER JOIN sys.types typ
				ON c.system_type_id = typ.system_type_id
		WHERE 
			t.name = 'StorageBenchmark' 
			AND typ.system_type_id = 167 --varchar
			--AND c.name = 'ID'

		OPEN mycur

		FETCH NEXT FROM mycur INTO @tableName, @columnName

		WHILE @@FETCH_STATUS = 0
		BEGIN

			SET @sql = 
				'UPDATE StorageBenchmark
				SET ' + QUOTENAME(@columnName) + ' = SUBSTRING(' + QUOTENAME(@columnName) +', 2, LEN(' + QUOTENAME(@columnName) +'))
				WHERE LEFT(' + QUOTENAME(@columnName) + ', 1) = ''"'';

				UPDATE StorageBenchmark
				SET ' + QUOTENAME(@columnName) + ' = SUBSTRING(' + QUOTENAME(@columnName) + ', 1, LEN(' + QUOTENAME(@columnName) + ')-1)
				WHERE RIGHT(' + QUOTENAME(@columnName) + ', 1) = ''"'';'

				--select @sql
				EXEC (@sql)
			--SELECT @tableName, @ColumnName
			FETCH NEXT FROM mycur INTO @tableName, @columnName
		END

	COMMIT TRAN

	CLOSE mycur
	DEALLOCATE mycur
	

	END TRY
	BEGIN CATCH
		SELECT 
			ERROR_NUMBER() AS ErrorNumber  
			,ERROR_SEVERITY() AS ErrorSeverity  
			,ERROR_STATE() AS ErrorState  
			,ERROR_PROCEDURE() AS ErrorProcedure  
			,ERROR_LINE() AS ErrorLine  
			,ERROR_MESSAGE() AS ErrorMessage;  


		ROLLBACK

		CLOSE mycur
		DEALLOCATE mycur
	END CATCH

