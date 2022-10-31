WITH LeadBlockers (blocker, blockee, level, sql)
AS
(
       SELECT s.blocked as blocker, s.spid as blockee, 0 as level, (SELECT text FROM ::fn_get_sql(s.sql_handle)) sql
       FROM   master..sysprocesses s
       WHERE  blocked = 0 AND EXISTS (SELECT * FROM master..sysprocesses inside WHERE inside.blocked = s.spid)
       UNION ALL
       SELECT s.blocked as blocker, s.spid as blockee, level + 1, (SELECT text FROM ::fn_get_sql(s.sql_handle)) sql
       FROM   master..sysprocesses s
                     INNER JOIN LeadBlockers
                                  ON s.blocked = LeadBlockers.blockee
)
SELECT *
FROM   LeadBlockers
ORDER BY level
