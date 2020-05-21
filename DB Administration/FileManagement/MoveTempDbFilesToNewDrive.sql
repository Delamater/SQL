-- Press ctrl+shift+m to replace template parameters
SELECT 'ALTER DATABASE tempdb MODIFY FILE (NAME = [' + f.name + '],'
	+ ' FILENAME = ''<FilePath, SYSNAME, D:\TempDB\>' + f.name
	+ CASE WHEN f.type = 1 THEN '.ldf' ELSE '.mdf' END
	+ '''' 
	+ CASE 
		WHEN f.type = 1 THEN ', SIZE = <Log FileSize,INTEGER,10000>);'
		ELSE ', SIZE = <FileSize,INTEGER,2000>);'
	  END	
FROM sys.master_files f
WHERE f.database_id = DB_ID(N'tempdb');
