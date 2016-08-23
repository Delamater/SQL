/*
https://www.simple-talk.com/sql/performance/tune-your-indexing-strategy-with-sql-server-dmvs/
Latching occurs when the engine reads a physical page. Upon doing so, 
it issues a latch, scans the page, reads the row, and then releases the 
latch when, and this is important, the page is needed for another process. 
This process is called lazy latching. Though latching is quite a benign process, 
it is of interest to have handy such information as this query provides. 
It allows us to identify which of our indexes are encountering significant waits 
when trying to issue a latch, because another latch has already been issued. 
I/O latching occurs on disk-to-memory transfers, and high I/O latch counts could 
be a reflection of a disk subsystem issue, particularly when you see average latch 
wait times of over 15 milliseconds.
*/

SELECT  '[' + DB_NAME() + '].[' + OBJECT_SCHEMA_NAME(ddios.[object_id])
        + '].[' + OBJECT_NAME(ddios.[object_id]) + ']' AS [object_name] ,
        i.[name] AS index_name ,
        ddios.page_io_latch_wait_count ,
        ddios.page_io_latch_wait_in_ms ,
        ( ddios.page_io_latch_wait_in_ms / ddios.page_io_latch_wait_count )
                                             AS avg_page_io_latch_wait_in_ms
FROM    sys.dm_db_index_operational_stats(DB_ID(), NULL, NULL, NULL) ddios
        INNER JOIN sys.indexes i ON ddios.[object_id] = i.[object_id]
                                    AND i.index_id = ddios.index_id
WHERE   ddios.page_io_latch_wait_count > 0
        AND OBJECTPROPERTY(i.OBJECT_ID, 'IsUserTable') = 1
ORDER BY ddios.page_io_latch_wait_count DESC ,
        avg_page_io_latch_wait_in_ms DESC 
