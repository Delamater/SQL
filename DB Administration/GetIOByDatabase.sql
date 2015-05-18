SELECT
		DB_NAME(DbId)[DB Name],
		FILE_NAME(FileId) [File Name],
		TimeStamp [Time Stamp],
		NumberReads [Number Of Reads],
		BytesRead [Bytes Read],
		IoStallReadMS [IO Stall Read MS],
		NumberWrites [Number of Writes],
		BytesWritten [Bytes Written],
		IoStallWriteMS [IO Stall Write MS],
		IoStallMS [IO Stall MS],
		BytesOnDisk [Bytes on Disk]
FROM sys.fn_virtualfilestats(NULL,NULL)
ORDER BY IoStallMS DESC
