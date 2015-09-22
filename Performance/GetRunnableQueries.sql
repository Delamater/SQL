/* List Runnable Queues */
/* Runnable queues are those queues 
waiting for CPU time. Signal waits are the time 
spent in the runnable queue waiting for the CPU */

SELECT scheduler_id, session_id, [status], command 
FROM sys.dm_exec_requests
WHERE 
	[status] = 'runnable'
	AND session_id > 50
ORDER BY scheduler_id
