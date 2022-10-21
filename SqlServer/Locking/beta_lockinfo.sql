/*---------------------------------------------------------------------
  $Header: /WWW/sqlutil/beta_lockinfo.sp 19    15-02-01 20:47 Sommar $

  This SP lists locking information for all active processes, that is
  processes that have a running request, is holding locks or have an
  open transaction. Information about all locked objects are included,
  as well the last command sent from the client and the currently
  running statement. The procedure also displays the blocking chain
  for blocked processes.

  Note that locks and processes are read indepently from the DMVs, and
  may not be wholly in sync. Likewise, object names and DBCC INPUTBUFFER
  are run later.

  This version of the procedure is for SQL 2012 and later. There are
  separate versions for SQL 2005 and SQL 2008.

  Parameters:
  @allprocesses - If 0, only include "interesting" processes, i.e.
                  processes running something or holding locks. 1 - also
                  include "half-interesting" processes. 2- include all
                  processes.
  @textmode     - If 0, output is sent as-is, intended for grid mode.
                  If 1, output columns are trimmed the width derived from
                  data, and a blank line is inserted between spids.
  @procdata     - A - show process-common data on all rows. F - show
                  process-common data only on the first rows. Defaults
                  to A in text mode and F in grid mode.
  @archivemode  - When non-NULL, instead of outputting data, save to the table
                  guest.beta_lockinfo. Delete data from the table that is
                  older than @archivemode minutes. When 0, only create the
                  table.
  @debug        - If 1, prints progress messages with timings.

  $History: beta_lockinfo.sp $
 * 
 * *****************  Version 19  *****************
 * User: Sommar       Date: 15-02-01   Time: 20:47
 * Updated in $/WWW/sqlutil
 * 1) Fix a potential overflow with last_since and trn_since.
 * 2) Added a workaround for the fact that data abou uncomitted heaps
 * cannot be accessed from sys.partitions in SQL 2014.
 * 3) Remove trailing NUL character from DBCC INPUTBUFFER.
 * 4) Incorrectly reset SET LOCK_TIMEOUT to 0, it should be -1.
 *
 * *****************  Version 18  *****************
 * User: Sommar       Date: 14-08-12   Time: 22:56
 * Updated in $/WWW/sqlutil
 * Had forgotten to consider negative values for last_since and trn_since
 * in the new format.
 *
 * *****************  Version 17  *****************
 * User: Sommar       Date: 14-08-12   Time: 22:23
 * Updated in $/WWW/sqlutil
 * 1) Bugfix: beta_lockfinfo died with an overflow error is the instance
 * had been up >= 115 days.
 * 2) Changed format of last_since and trn_since to be days +
 * hh:mm:ss.fff.
 *
 * *****************  Version 16  *****************
 * User: Sommar       Date: 14-01-29   Time: 22:39
 * Updated in $/WWW/sqlutil
 * The parameter @allprocesses now take three values 0, 1, 2. 2 shows all
 * processes, while 1 includes "half-interesting" processes. The processes
 * that now are considered "half-interesting" were previously considered
 * "interesting" and were always displayed, but they added to much noise
 * to the output. See further the section Interesting and Half-interesting
 * Processes.
 *
 * Introducing archive mode, controlled by the new parameter @archivemode.
 * In archive mode, beta_lockinfo does not produce any output, but writes
 * the data to a table. I also provide BAT files so that you easily can
 * ask someone at a remote site to run beta_lockinfo for you.
 *
 * There are no three versions of beta_lockinfo: one for SQL 2005, one for
 * SQL 2008 and one for SQL 2012 and later.
 *
 * New column in the output: memgrant, that shows the memory grant for the
 * current query for a process.
 *
 * The column rscsubtype has been augmented to also display locking
 * partitions on servers with 16 or more schedulers.
 *
 * Bugfix: a lock timeout on more than 32 767 ms would cause arithmetic
 * overflow in beta_lockinfo.
 *
 * beta_lockinfo no longer shows a blank value for last_since if the
 * process has been logged in for more than 20 days.
 *
 * Text mode was prone to yield an error about string truncation when
 * there was blocking between exec contexts.
 *
 * On SQL 2012, the statement text was stripped out from the query plans.
 * (Because beta_lockinfo corrected for a bug which exists in SQL 2008 and
 * SQL 2005, but is corrected in SQL 2012.)
 *
 * Changed the order in which beta_lockinfo retrieves information, so that
 * locks are now retrieved after the processes. This will not reduced the
 * amount of inconsistencies you will see on a busy system, but they will
 * be somewhat different in nature. :-)
 *
 * *****************  Version 15  *****************
 * User: Sommar       Date: 12-11-18   Time: 19:14
 * Updated in $/WWW/sqlutil
 * Added three new columns ansiopts (to display deviate settings of
 * ANSI-relatedl SET options), trnopts (to display deviating
 * transaction-related SET options and progress (shows how work that has
 * been performed for some types of statements).
 *
 * beta_lockinfo now displays waiting tasks that are not bound to a
 * session it they have an "interesting" wait type, that is, wait types
 * commonly used by system process are ignored. Such tasks have session id
 * < -1000 in the display. The most common such wait type is THREADPOOL
 * which means that you have run out of worker threads.
 *
 *
 * *****************  Version 14  *****************
 * User: Sommar       Date: 11-01-28   Time: 22:47
 * Updated in $/WWW/sqlutil
 * Temp tables are now displayed as #name only. No tempdb prefix, and
 * without the system-generated suffix to make the name unique in the
 * system catalog. Furthermore, if a process has created several temp
 * tables with the same name, the rows for these tables are aggregated to
 * one row per lock type, and a number in parentheses is added to indicate
 * the number of temp tables with that name. (The typical situations when
 * this happens is when a procedure is called several times in the same
 * transaction.) The change does not affect global temp tables.
 *
 * Table variables and other entries in the tempdb system catalog that
 * consists of a # and eight hex digits are now displayed as #(tblvar or
 * dropped temp table). As with temp tables, they are aggrgated into a
 * single row per lockwith a number added if there are several of them.
 *
 * *****************  Version 13  *****************
 * User: Sommar       Date: 10-11-21   Time: 23:17
 * Updated in $/WWW/sqlutil
 * 1) Added column to show tempdb usage.
 * 2) Process is "interesting" if it allocates more than 1000 pages in
 * tempdb.
 * 3) Bugfix: Had broken procedure name translation, so current_sp was
 * always blank.
 * 4) Bugfix: procedure name and current statement was missing from text
 * mode.
 * 5) Added permission check, so procedure fails if run without VIEW
 * SERVER STATE.
 * 6) Added LOCK_TIMEOUT and error handling for object-name translation,
 * as you are blocked on SQL 2005 and SQL 2008 on system tables, if you
 * are not sysadmin. In this case, you get the error message instead of
 * the object name.
 *
 * *****************  Version 12  *****************
 * User: Sommar       Date: 09-06-25   Time: 23:22
 * Updated in $/WWW/sqlutil
 * Added checks of the SQL version and the compatibility level. Added
 * columns to give information about current transactions. Fixed textmode
 * that was broken.
 *
 * *****************  Version 11  *****************
 * User: Sommar       Date: 09-01-31   Time: 20:01
 * Updated in $/WWW/sqlutil
 * 1) The procedure body now reads ALTER PROCEDURE, and the script creates
 * a dummy procedure if beta_lockinfo does not exist.
 * 2) Retrieving query texts separately, to handle the case that a process
 * creates a procedure within a transaction and then executes it without
 * committing the transaction. In this case beta_lockinfo gets blocked,
 * and we fall back to get texts spid by spid.
 *
 * *****************  Version 10  *****************
 * User: Sommar       Date: 09-01-10   Time: 22:18
 * Updated in $/WWW/sqlutil
 * Fixed bug that caused NULL violation when there was a lock on a dropped
 * allocatoin unit.
 *
 * *****************  Version 9  *****************
 * User: Sommar       Date: 08-11-04   Time: 21:51
 * Updated in $/WWW/sqlutil
 * Failed to consider that a lead blocker may be waiting too, if not for
 * another spid.
 *
 * *****************  Version 8  *****************
 * User: Sommar       Date: 08-11-03   Time: 23:30
 * Updated in $/WWW/sqlutil
 * 1) Incorrectly showed NULL in blkby when process was not blocked.
 * 2) When modifying the XML document for the plan, we need to consider
 * that our statement information may be NULL, or else .modify blows up.
 *
 * *****************  Version 7  *****************
 * User: Sommar       Date: 08-11-02   Time: 20:55
 * Updated in $/WWW/sqlutil
 * Reworked the block-chain handling,so that deadlocks are detected and
 * marked with DD in the block_chain column. We also find processes that
 * are blocked by the deadlocked processes. We now also mark processes
 * that waiting for a lock, but are not in the block_chain (because they
 * started waiting after we read dm_os_waiting_tasks.)
 *
 * *****************  Version 6  *****************
 * User: Sommar       Date: 08-11-01   Time: 22:13
 * Updated in $/WWW/sqlutil
 * 1) Work around bug in dm_exec_text_query_plan that causes bloat in the
 * return XML plan.
 * 2) Show database name for application locks.
 * 3) Show object_id directly when we cannot translate it.
 * 4) Return the statement text in full on the first row for a process
 * only.
 * 5) For some resource types, for instance METADATA there were two
 * identical lines displayed, because we incorrectly groupe on
 * rsc_description for other resource types than application locks.
 *
 * *****************  Version 5  *****************
 * User: Sommar       Date: 08-08-16   Time: 23:22
 * Updated in $/WWW/sqlutil
 * CRLF in text mode was replaced with the empty string, not spaces.
 *
 * *****************  Version 4  *****************
 * User: Sommar       Date: 08-08-16   Time: 23:13
 * Updated in $/WWW/sqlutil
 * 1) Run with a short lock-timeout when retrieving query plans. According
 * to SQL Server MVP Adam Machanic, this can occur. I'm therefore now
 * including the error message if the query plan cannot be retrieved.
 * 2) Error handling for DBCC INPUTBUFFER, as on SQL 2008 a missing spid
 * raises an error.
 *
 * *****************  Version 3  *****************
 * User: Sommar       Date: 07-12-09   Time: 23:15
 * Updated in $/WWW/sqlutil
 * 1] Implemented a workaround to avoid the problem with duplicates keys
 * that occur when the two tasks got the same execution context id.
 * 2) Also worked around a case where dm_os_waiting_tasks can include
 * duplicate rows.
 * 3) If a thread is only blocking other threads or requests in the same
 * thread, put the value in block_level in parentheses.
 * 4) Added an indicator in the blkby column on how many other tasks
 * that may be blocking.
 * 5) The spid string now uses slashes as delimiter. This is because that
 * use -1 indicate that a task was that was blocking had exited when
 * we merge the block chain with the processes.
 * 6) I'm now reading sys.dm_exec_sessions and related views more
 * directly after reading sys.dm_os_waiting_tasks to increase the odds
 * for a consistent view.
 *
 * *****************  Version 2  *****************
 * User: Sommar       Date: 07-11-18   Time: 20:49
 * Updated in $/WWW/sqlutil
 * 1) Adding error handling around INSERTs that are known to bomb on
 *    PK violation, and produce a debug output, so we can find out what is
 * going on.
 * 2) Added fallback for the possible case that the query plan is not
 *   convertible to XML. Kudos to SQL Server MVP Razvan Socol for
 *   giving me a test case.
 *
 * *****************  Version 1  *****************
 * User: Sommar       Date: 07-07-29   Time: 0:09
 * Created in $/WWW/sqlutil
  ---------------------------------------------------------------------*/

-- Version check
DECLARE @version  varchar(20)
SELECT  @version = convert(varchar, serverproperty('ProductVersion'))
IF @version NOT LIKE '[0-9][0-9].%'
   SELECT @version = '0' + @version
IF @version < '11'
   RAISERROR('This version of beta_lockinfo requires SQL Server 2008 or later', 16, 127)
go
-- Create shell.
IF object_id('beta_lockinfo') IS NULL EXEC ('CREATE PROCEDURE beta_lockinfo AS PRINT 12')
go
-- And here comes the procedure itself!
ALTER PROCEDURE beta_lockinfo @allprocesses  tinyint = 0,
                              @textmode      bit     = 0,
                              @procdata      char(1) = NULL,
                              @archivemode   int     = NULL,
                              @debug         bit     = 0 AS

-----------------------------------------------------------------------
-- Table variables/temp tables in order of appearance.
-----------------------------------------------------------------------

-- This table captures sys.dm_os_waiting_tasks and later augment it with
-- data about the block chain. A waiting task always has a always has a
-- task address, but the blocker may be idle and without a task.
-- All columns for the blocker are nullable, as we add extra rows for
-- non-waiting blockers. The indexes has IGNORE_DUP_KEY = ON, because
-- they are unique in theory, but not really in practice.
DECLARE @dm_os_waiting_tasks TABLE
   (wait_session_id   smallint     NOT NULL,
    wait_task         varbinary(8) NOT NULL,
    block_session_id  smallint     NULL,
    block_task        varbinary(8) NULL,
    wait_type         varchar(60) COLLATE Latin1_General_BIN2  NULL,
    wait_duration_ms  bigint       NULL,
    -- The level in the chain. Level 0 is the lead blocker. NULL for
    -- tasks that are waiting, but not blocking.
    block_level       smallint     NULL,
    -- The lead blocker for this block chain.
    lead_blocker_spid smallint     NULL,
    -- Whether the block chain consists of the threads of the same spid only.
    blocksamespidonly bit          NOT NULL DEFAULT 0,
  UNIQUE CLUSTERED (wait_session_id, wait_task, block_session_id, block_task) WITH (IGNORE_DUP_KEY = ON),
  UNIQUE (block_session_id, block_task, wait_session_id, wait_task) WITH (IGNORE_DUP_KEY = ON)
)


-- This table holds information about transactions tied to a session.
-- A session can have multiple transactions when there are multiple
-- requests, but in that case we only save data about the oldest
-- transaction.
DECLARE @transactions TABLE (
   session_id       smallint      NOT NULL,
   is_user_trans    bit           NOT NULL,
   trans_start      datetime      NOT NULL,
   trans_since      decimal(10,3) NULL,
   trans_type       int           NOT NULL,
   trans_state      int           NOT NULL,
   dtc_state        int           NOT NULL,
   is_bound         bit           NOT NULL,
   PRIMARY KEY (session_id)
)


-- This table holds information about all sessions and requests.
DECLARE @procs TABLE (
   session_id       smallint      NOT NULL,
   task_address     varbinary(8)  NOT NULL,
   exec_context_id  int           NOT NULL,
   request_id       int           NOT NULL,
   spidstr AS ltrim(str(session_id)) +
              CASE WHEN exec_context_id <> 0 OR request_id <> 0
                   THEN '/' + ltrim(str(exec_context_id)) +
                        '/' + ltrim(str(request_id))
                   ELSE ''
              END,
   is_user_process  bit           NULL,
   orig_login       nvarchar(128) COLLATE Latin1_General_BIN2 NULL,
   current_login    nvarchar(128) COLLATE Latin1_General_BIN2 NULL,
   session_state    varchar(30)   COLLATE Latin1_General_BIN2 NOT NULL DEFAULT ' ',
   task_state       varchar(60)   COLLATE Latin1_General_BIN2 NULL,
   proc_dbid        smallint      NULL,
   request_dbid     smallint      NULL,
   host_name        nvarchar(128) COLLATE Latin1_General_BIN2 NULL,
   host_process_id  int           NULL,
   endpoint_id      int           NULL,
   program_name     nvarchar(128) COLLATE Latin1_General_BIN2 NULL,
   request_command  nvarchar(32)  COLLATE Latin1_General_BIN2 NULL,
   trancount        int           NOT NULL DEFAULT 0,
   session_cpu      int           NULL,
   request_cpu      int           NULL,
   session_physio   bigint        NULL,
   request_physio   bigint        NULL,
   session_logreads bigint        NULL,
   request_logreads bigint        NULL,
   session_tempdb   bigint        NULL,
   request_tempdb   bigint        NULL,
   percent_complete real          NULL,
   memory_grant     decimal(18,3) NULL,
   quoted_id        bit           NOT NULL DEFAULT 1,
   arithabort       bit           NOT NULL DEFAULT 0,
   ansi_null_dflt   bit           NOT NULL DEFAULT 1,
   ansi_defaults    bit           NOT NULL DEFAULT 0,
   ansi_warns       bit           NOT NULL DEFAULT 1,
   ansi_pad         bit           NOT NULL DEFAULT 1,
   ansi_nulls       bit           NOT NULL DEFAULT 1,
   concat_null      bit           NOT NULL DEFAULT 1,
   isolation_lvl    smallint      NOT NULL DEFAULT 2,
   deadlock_pri     int           NULL,
   lock_timeout     int           NULL,
   isclr            bit           NOT NULL DEFAULT 0,
   nest_level       int           NULL,
   login_time       datetime      NULL,
   last_batch       datetime      NULL,
   last_since       decimal(18,3) NULL,
   curdbid          smallint      NULL,
   curobjid         int           NULL,
   current_stmt     nvarchar(MAX) COLLATE Latin1_General_BIN2 NULL,
   sql_handle       varbinary(64) NULL,
   plan_handle      varbinary(64) NULL,
   stmt_start       int           NULL,
   stmt_end         int           NULL,
   current_plan     xml           NULL,
   procrowno        int           NOT NULL,
   block_level      tinyint       NULL,
   block_session_id smallint      NULL,
   block_exec_context_id int      NULL,
   block_request_id      int      NULL,
   blockercnt        int          NULL,
   block_spidstr AS ltrim(str(block_session_id)) +
               CASE WHEN block_exec_context_id <> 0 OR block_request_id <> 0
                    THEN '/' + ltrim(str(block_exec_context_id)) +
                         '/' + ltrim(str(block_request_id))
                    ELSE ''
               END +
               CASE WHEN blockercnt > 1
                    THEN ' (+' + ltrim(str(blockercnt - 1)) + ')'
                    ELSE ''
               END,
   blocksamespidonly bit          NOT NULL DEFAULT 0,
   waiter_no_blocker bit          NOT NULL DEFAULT 0,
   wait_type        varchar(60)   COLLATE Latin1_General_BIN2 NULL,
   wait_time        decimal(18,3) NULL,
   activity_level   tinyint,
   PRIMARY KEY (session_id, task_address))


-- This table holds the initial extraction from sys.dm_tran_locks, where we
-- aggregate on a number of items, including lock_partition but excluding
-- subthreads. The groupno column is a surrogate key for all aggregation
-- properties but lock_partition, so that we don't have put all those strings
-- in the index.
DECLARE @locks_takeone TABLE (
   database_id         int      NOT NULL,
   entity_id           bigint   NULL,
   session_id          int      NOT NULL,
   req_mode            varchar(60)   COLLATE Latin1_General_BIN2 NOT NULL,
   rsc_type            varchar(60)   COLLATE Latin1_General_BIN2 NOT NULL,
   rsc_subtype         varchar(60)   COLLATE Latin1_General_BIN2 NOT NULL,
   req_status          varchar(60)   COLLATE Latin1_General_BIN2 NOT NULL,
   req_owner_type      varchar(60)   COLLATE Latin1_General_BIN2 NOT NULL,
   rsc_description     nvarchar(256) COLLATE Latin1_General_BIN2 NULL,
   lock_partition      int      NULL,
   cnt                 int      NOT NULL,
   groupno             int      NOT NULL,
   activelock AS CASE WHEN rsc_type = 'DATABASE' AND
                           req_status = 'GRANT'
                      THEN convert(bit, 0)
                      ELSE convert(bit, 1)
                 END,
   -- Here comes the indexes. The real key is (groupno, lock_partition), but
   -- cnt is added to the first index, as that is good when we aggregate out
   -- lock partition.
   UNIQUE NONCLUSTERED (groupno, lock_partition, cnt),
   -- And this index is good when marking active processes.
   UNIQUE NONCLUSTERED (session_id, activelock, groupno, lock_partition)
)

-- Output from DBCC INPUTBUFFER. The IDENTITY column is there to make
-- it possible to add the spid later.
DECLARE @inputbuffer TABLE
       (eventtype    nvarchar(30)   NULL,
        params       int            NULL,
        inputbuffer  nvarchar(4000) NULL,
        ident        int            IDENTITY UNIQUE,
        spid         int            NOT NULL DEFAULT 0 PRIMARY KEY)


-- @locks_takeone is later aggreated into this table where the lock paritions
-- are represented as a string.
DECLARE @locks_final TABLE (
   database_id         int      NOT NULL,
   entity_id           bigint   NULL,
   session_id          int      NOT NULL,
   req_mode            varchar(60)   COLLATE Latin1_General_BIN2 NOT NULL,
   rsc_type            varchar(60)   COLLATE Latin1_General_BIN2 NOT NULL,
   rsc_subtype         varchar(60)   COLLATE Latin1_General_BIN2 NOT NULL,
   req_status          varchar(60)   COLLATE Latin1_General_BIN2 NOT NULL,
   req_owner_type      varchar(60)   COLLATE Latin1_General_BIN2 NOT NULL,
   rsc_description     nvarchar(256) COLLATE Latin1_General_BIN2 NULL,
   lock_partitions     varchar(1000) COLLATE Latin1_General_BIN2 NULL,
   min_entity_id       bigint   NULL,
   ismultipletemp      bit      NOT NULL DEFAULT 0,
   cnt                 int      NOT NULL,
   groupno             int      NOT NULL,
   lockno              int      NULL     -- Set per session_id if @procdata is F.
   PRIMARY KEY NONCLUSTERED (groupno),
   UNIQUE  CLUSTERED (session_id, database_id, entity_id, groupno)
)


-- This table holds the translation of entity_id in @locks. This is a
-- temp table since we access it from dynamic SQL. The type_desc is used
-- for allocation units. The columns session_id, min_id and cnt are used
-- when consolidating temp tables.
CREATE TABLE #objects (
     idtype         char(4)       NOT NULL
        CHECK (idtype IN ('OBJ', 'HOBT', 'AU', 'MISC')),
     database_id    int           NOT NULL,
     entity_id      bigint        NOT NULL,
     hobt_id        bigint        NULL,
     object_name    nvarchar(550) COLLATE Latin1_General_BIN2 NULL,
     type_desc      varchar(60)   COLLATE Latin1_General_BIN2 NULL,
     session_id     smallint      NULL,
     min_id         bigint        NOT NULL,
     cnt            int           NOT NULL DEFAULT 1
     PRIMARY KEY CLUSTERED (database_id, idtype, entity_id),
     UNIQUE NONCLUSTERED (database_id, entity_id, idtype),
     CHECK (NOT (session_id IS NOT NULL AND database_id <> 2))
)


-- And this is the temp table where we save the final output.
CREATE TABLE #output(
       spid        varchar(30)    COLLATE Latin1_General_BIN2 NOT NULL,
       command     nvarchar(32)   COLLATE Latin1_General_BIN2 NULL,
       login       nvarchar(260)  COLLATE Latin1_General_BIN2 NULL,
       host        nvarchar(128)  COLLATE Latin1_General_BIN2 NULL,
       hostprc     varchar(10)    COLLATE Latin1_General_BIN2 NULL,
       endpoint    sysname        COLLATE Latin1_General_BIN2 NULL,
       appl        nvarchar(128)  COLLATE Latin1_General_BIN2 NULL,
       dbname      sysname        COLLATE Latin1_General_BIN2 NULL,
       prcstatus   nvarchar(60)   COLLATE Latin1_General_BIN2 NULL,
       ansiopts    varchar(50)    COLLATE Latin1_General_BIN2 NULL,
       spid_       varchar(30)    COLLATE Latin1_General_BIN2 NULL,
       trnopts     varchar(60)    COLLATE Latin1_General_BIN2 NULL,
       opntrn      varchar(10)    COLLATE Latin1_General_BIN2 NULL,
       trninfo     varchar(60)    COLLATE Latin1_General_BIN2 NULL,
       blklvl      varchar(10)    COLLATE Latin1_General_BIN2 NOT NULL,
       blkby       varchar(30)    COLLATE Latin1_General_BIN2 NOT NULL,
       cnt         varchar(10)    COLLATE Latin1_General_BIN2 NOT NULL,
       object      nvarchar(550)  COLLATE Latin1_General_BIN2 NULL,
       rsctype     nvarchar(60)   COLLATE Latin1_General_BIN2 NOT NULL,
       locktype    nvarchar(60)   COLLATE Latin1_General_BIN2 NOT NULL,
       lstatus     nvarchar(60)   COLLATE Latin1_General_BIN2 NOT NULL,
       ownertype   nvarchar(60)   COLLATE Latin1_General_BIN2 NOT NULL,
       rscsubtype  varchar(1100)  COLLATE Latin1_General_BIN2 NOT NULL,
       waittime    varchar(19)    COLLATE Latin1_General_BIN2 NULL,
       waittype    nvarchar(60)   COLLATE Latin1_General_BIN2 NULL,
       spid__      varchar(30)    COLLATE Latin1_General_BIN2 NULL,
       cpu         varchar(25)    COLLATE Latin1_General_BIN2 NULL,
       physio      varchar(40)    COLLATE Latin1_General_BIN2 NULL,
       logreads    varchar(40)    COLLATE Latin1_General_BIN2 NULL,
       memgrant    varchar(19)    COLLATE Latin1_General_BIN2 NULL,
       progress    varchar(5)     COLLATE Latin1_General_BIN2 NULL,
       tempdb      varchar(40)    COLLATE Latin1_General_BIN2 NULL,
       now         char(12)       COLLATE Latin1_General_BIN2 NOT NULL,
       login_time  varchar(16)    COLLATE Latin1_General_BIN2 NULL,
       last_batch  varchar(16)    COLLATE Latin1_General_BIN2 NULL,
       trn_start   varchar(16)    COLLATE Latin1_General_BIN2 NULL,
       last_since  varchar(17)    COLLATE Latin1_General_BIN2 NULL,
       trn_since   varchar(17)    COLLATE Latin1_General_BIN2 NULL,
       clr         char(3)        COLLATE Latin1_General_BIN2 NULL,
       nstlvl      char(3)        COLLATE Latin1_General_BIN2 NULL,
       spid___     varchar(30)    COLLATE Latin1_General_BIN2 NULL,
       inputbuffer nvarchar(4000) COLLATE Latin1_General_BIN2 NULL,
       current_sp  nvarchar(400)  COLLATE Latin1_General_BIN2 NULL,
       curstmt     nvarchar(MAX)  COLLATE Latin1_General_BIN2 NULL,
       queryplan   xml            NULL,
       rowno       int            NOT NULL,
       spidnum     smallint       NOT NULL,
       PRIMARY KEY (rowno)
)




------------------------------------------------------------------------
-- Local variables.
------------------------------------------------------------------------
DECLARE @now            datetime2(3) = sysdatetime(),
        @version        varchar(20) = convert(varchar, serverproperty('ProductVersion')),
        @ms             int,
        @spid           smallint,
        @rowc           int,
        @lvl            int,
        @dbname         sysname,
        @dbidstr        varchar(10),
        @objnameexpr    nvarchar(MAX),
        @stmt           nvarchar(MAX),
        @request_id     int,
        @handle         varbinary(64),
        @stmt_start     int,
        @stmt_end       int,
        @partition_hint nvarchar(50)

------------------------------------------------------------------------
-- Set up.
------------------------------------------------------------------------
-- All reads are dirty! This is particularly important when getting objects
-- names, which may have been created in a transaction. (Think temp tables.)
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SET NOCOUNT ON;

-- Validate the @procdata parameter, and set default.
IF @procdata IS NULL
   SELECT @procdata = CASE @textmode WHEN 1 THEN 'A' ELSE 'F' END
IF @procdata NOT IN ('A', 'F')
BEGIN
   RAISERROR('Invalid value for @procdata parameter. A and F are permitted', 16, 1)
   RETURN
END

-- Check that user has permissions enough.
IF NOT EXISTS (SELECT *
               FROM   sys.fn_my_permissions(NULL, NULL)
               WHERE  permission_name = 'VIEW SERVER STATE')
BEGIN
   RAISERROR('You need to have the permission VIEW SERVER STATE to run this procedure', 16, 1)
   RETURN
END

IF @textmode = 1 AND @archivemode IS NOT NULL
BEGIN
   RAISERROR('You cannot combine @textmode and @archivemode.', 16, 1)
   RETURN
END

IF @archivemode IS NOT NULL AND
   NOT EXISTS (SELECT *
               FROM   sys.fn_my_permissions(NULL, 'Database')
               WHERE  permission_name = 'CONTROL')
BEGIN
   RAISERROR('To use @archivemode you need to have CONTROL permission in the database where beta_lockinfo is located.', 16, 1)
   RETURN
END

-- If @archivemode is 0 (or negative), all we do is to create the table.
IF @archivemode <= 0 GOTO do_archive

-----------------------------------------------------------------------
-- Capture sys.dm_os_waiting_tasks.
-----------------------------------------------------------------------
IF @debug = 1
BEGIN
   SELECT @ms = datediff(ms, @now, sysdatetime())
   RAISERROR ('Determining blocking chain, time %d ms.', 0, 1, @ms) WITH NOWAIT
END

-- We want want all waits tied to a session, but also some system waits.
-- (Particularly THREADPOOL, but who knows, others may also be of interest.)
-- DISTINCT is needed, because there may be duplicates. (I've seen them.)
INSERT @dm_os_waiting_tasks (wait_session_id, wait_task, block_session_id,
                             block_task, wait_type, wait_duration_ms)
   SELECT coalesce(owt.session_id,
               -1 * (1000 + row_number() OVER(ORDER BY (SELECT 1)))),
          owt.waiting_task_address, owt.blocking_session_id,
          CASE WHEN owt.blocking_session_id IS NOT NULL
               THEN coalesce(owt.blocking_task_address, 0x)
          END, owt.wait_type, owt.wait_duration_ms
   FROM   sys.dm_os_waiting_tasks owt
   WHERE  owt.session_id IS NOT NULL OR
          owt.wait_type NOT IN ('FT_IFTS_SCHEDULER_IDLE_WAIT', 'CLR_AUTO_EVENT',
                                'CLR_MANUAL_EVENT', 'DISPATCHER_QUEUE_SEMAPHORE',
                                'FILESTREAM_WORKITEM_QUEUE')

-----------------------------------------------------------------------
-- Get active transactions.
-----------------------------------------------------------------------
IF @debug = 1
BEGIN
   SELECT @ms = datediff(ms, @now, sysdatetime())
   RAISERROR ('Determining active transactions, time %d ms.', 0, 1, @ms) WITH NOWAIT
END

; WITH oldest_tran AS (
    SELECT tst.session_id, tst.is_user_transaction,
           tat.transaction_begin_time, tat.transaction_type,
           tat.transaction_state, tat.dtc_state, tst.is_bound,
           rowno = row_number() OVER (PARTITION BY tst.session_id
                                      ORDER BY tat.transaction_begin_time ASC)
    FROM   sys.dm_tran_session_transactions tst
    JOIN   sys.dm_tran_active_transactions tat
       ON  tst.transaction_id = tat.transaction_id
)
INSERT @transactions(session_id, is_user_trans, trans_start,
                     trans_since,
                     trans_type, trans_state, dtc_state, is_bound)
   SELECT session_id, is_user_transaction, transaction_begin_time,
          CASE WHEN abs(datediff(YEAR, transaction_begin_time, @now)) > 60
               THEN NULL
               WHEN datediff(DAY, transaction_begin_time, @now) > 20
               THEN datediff(SECOND, transaction_begin_time,  @now)
               ELSE datediff(MS, transaction_begin_time,  @now) / 1000.000
          END,
          transaction_type, transaction_state, dtc_state, is_bound
   FROM   oldest_tran
   WHERE  rowno = 1

------------------------------------------------------------------------
-- Next step is to get all processes.
------------------------------------------------------------------------
IF @debug = 1
BEGIN
   SELECT @ms = datediff(ms, @now, sysdatetime())
   RAISERROR ('Collecting process information, time %d ms.', 0, 1, @ms) WITH NOWAIT
END

INSERT @procs(session_id, task_address,
              exec_context_id, request_id,
              is_user_process,
              current_login,
              orig_login,
              session_state, task_state, endpoint_id,
              proc_dbid, request_dbid,
              host_name, host_process_id, program_name, request_command,
              trancount,
              session_cpu, request_cpu,
              session_physio, request_physio,
              session_logreads, request_logreads,
              session_tempdb,
              request_tempdb, percent_complete, memory_grant,
              quoted_id,
              arithabort,
              ansi_null_dflt,
              ansi_defaults,
              ansi_warns,
              ansi_pad,
              ansi_nulls,
              concat_null,
              isolation_lvl,
              lock_timeout,
              deadlock_pri,
              isclr, nest_level,
              login_time, last_batch,
              last_since,
              sql_handle, plan_handle,
              stmt_start, stmt_end,
              procrowno,
              activity_level)
   SELECT es.session_id, coalesce(ot.task_address, 0x),
          coalesce(ot.exec_context_id, 0), coalesce(er.request_id, 0),
          es.is_user_process,
          coalesce(nullif(es.login_name, ''), suser_sname(es.security_id)),
          coalesce(nullif(es.original_login_name, ''),
                   suser_sname(es.original_security_id)),
          es.status, ot.task_state, es.endpoint_id,
          es.database_id, er.database_id,
          es.host_name, es.host_process_id, es.program_name, er.command,
          coalesce(er.open_transaction_count, es.open_transaction_count),
          es.cpu_time, er.cpu_time,
          es.reads + es.writes, er.reads + er.writes,
          es.logical_reads, er.logical_reads,
          ssu.user_objects_alloc_page_count -
             ssu.user_objects_dealloc_page_count +
             ssu.internal_objects_alloc_page_count -
             ssu.internal_objects_dealloc_page_count,
          tsu.pages, nullif(er.percent_complete, 0),
          convert(bigint, er.granted_query_memory) * 8192 / 1E6,
          coalesce(er.quoted_identifier, es.quoted_identifier),
          coalesce(er.arithabort, es.arithabort),
          coalesce(er.ansi_null_dflt_on, es.ansi_null_dflt_on),
          coalesce(er.ansi_defaults, es.ansi_defaults),
          coalesce(er.ansi_warnings, es.ansi_warnings),
          coalesce(er.ansi_padding, es.ansi_padding),
          coalesce(er.ansi_nulls, es.ansi_nulls),
          coalesce(er.concat_null_yields_null, es.concat_null_yields_null),
          coalesce(er.transaction_isolation_level, es.transaction_isolation_level),
          nullif(coalesce(er.lock_timeout, es.lock_timeout), -1),
          nullif(coalesce(er.deadlock_priority, es.deadlock_priority), 0),
          coalesce(er.executing_managed_code, 0), er.nest_level,
          es.login_time, es.last_request_start_time,
          CASE WHEN abs(datediff(YEAR, es.last_request_start_time, @now)) > 60
               THEN NULL
               WHEN datediff(DAY, es.last_request_start_time, @now) > 20
               THEN datediff(SECOND, es.last_request_start_time,  @now)
               ELSE datediff(MS, es.last_request_start_time,  @now) / 1000.000
          END,
          er.sql_handle, er.plan_handle,
          er.statement_start_offset, er.statement_end_offset,
          procrowno = row_number() OVER (PARTITION BY es.session_id
                                      ORDER BY ot.exec_context_id, er.request_id),
          -- The activity_level determines how interesting a process is and
          -- matches the parameter @allprocesses. That is, 2 is for processes
          -- only to be includedwhen @allprocesses is 2.
          CASE -- A blocking task is always interesting.
               WHEN EXISTS (SELECT *
                       FROM   @dm_os_waiting_tasks owt
                       WHERE  owt.block_session_id = es.session_id) THEN 0

               -- A running user-process is always of interest, unless it is
               -- ourselves, or an SB activation procedure waiting for a message.
               WHEN ot.exec_context_id IS NOT NULL AND
                    es.is_user_process = 1  AND
                    es.session_id <> @@spid AND
                    coalesce(er.wait_type, '') <> 'BROKER_RECEIVE_WAITFOR' THEN 0

               -- A process with an open transction is half-interesting.
               WHEN es.open_transaction_count > 0 THEN 1

               -- As are waiting SB processes
               WHEN ot.exec_context_id IS NOT NULL AND
                    er.wait_type = 'BROKER_RECEIVE_WAITFOR' THEN 1

               -- Processes with a high tempdb consumption are half-interesting.
               WHEN  ssu.user_objects_alloc_page_count -
                     ssu.user_objects_dealloc_page_count +
                     ssu.internal_objects_alloc_page_count -
                     ssu.internal_objects_dealloc_page_count > 1000 THEN 1

               -- Everything else is not of interest so far. (But this may change when we
               -- look at locks.
               ELSE 2
          END
   FROM   sys.dm_exec_sessions es
   LEFT   JOIN sys.dm_os_tasks ot ON es.session_id = ot.session_id
   LEFT   JOIN sys.dm_exec_requests er ON ot.task_address = er.task_address
   LEFT   JOIN sys.dm_db_session_space_usage ssu ON es.session_id = ssu.session_id
   LEFT   JOIN (SELECT session_id, request_id,
                       SUM(isnull(user_objects_alloc_page_count, 0) -
                           isnull(user_objects_dealloc_page_count, 0) +
                           isnull(internal_objects_alloc_page_count, 0) -
                           isnull(internal_objects_dealloc_page_count, 0)) AS pages
                FROM   sys.dm_db_task_space_usage
                WHERE  database_id = 2
                GROUP  BY session_id, request_id) AS tsu
            ON tsu.session_id = er.session_id
           AND tsu.request_id = er.request_id

------------------------------------------------------------------------
-- Add waiting tasks that do not have real session ids for some reason.
-- (Could have exited, could be THREADPOOL waits.)
------------------------------------------------------------------------
IF @debug = 1
BEGIN
   SELECT @ms = datediff(ms, @now, sysdatetime())
   RAISERROR ('Collecting process information for tasks without sessions, time %d ms.', 0, 1, @ms) WITH NOWAIT
END

INSERT @procs(session_id,
              task_address,
              exec_context_id, request_id,
              task_state,  procrowno, wait_time,
              wait_type, activity_level)
   SELECT coalesce(pt.session_id, owt.wait_session_id),
          coalesce(t.task_address, 0x),
          CASE WHEN pt.session_id IS NOT NULL THEN -9 ELSE 0 END, 0,
          coalesce(t.task_state, 'EXITED'), 1, owt.wait_duration_ms,
          owt.wait_type, 0
   FROM   @dm_os_waiting_tasks owt
   LEFT   JOIN  sys.dm_os_tasks t ON t.task_address  = owt.wait_task
   LEFT   JOIN  sys.dm_os_tasks pt ON t.parent_task_address = pt.task_address
   WHERE  owt.wait_session_id < -1000

-- Delete these sessions, so they don't confuse the blocking chains.
DELETE @dm_os_waiting_tasks WHERE wait_session_id < -1000


------------------------------------------------------------------------
-- Now we capture the locks, which can take some time if there are many
-- of them. We aggregate in two steps, to be able to get the lock
-- partitions as a list.
------------------------------------------------------------------------
IF @debug = 1
BEGIN
   SELECT @ms = datediff(ms, @now, sysdatetime())
   RAISERROR ('Compiling lock information, time %d ms.', 0, 1, @ms) WITH NOWAIT
END

-- We force binary collation, to make the GROUP BY operation faster. Note that
-- the ORDER BY clause for rank(), includes all columns in the GROUP BY save
-- for lock_partition.
; WITH CTE AS (
   SELECT request_session_id,
          req_mode        = request_mode       COLLATE Latin1_General_BIN2,
          rsc_type        = resource_type      COLLATE Latin1_General_BIN2,
          rsc_subtype     = resource_subtype   COLLATE Latin1_General_BIN2,
          req_status      = request_status     COLLATE Latin1_General_BIN2,
          req_owner_type  = request_owner_type COLLATE Latin1_General_BIN2,
          rsc_description =
             CASE WHEN resource_type = 'APPLICATION'
                  THEN nullif(resource_description
                              COLLATE Latin1_General_BIN2, '')
             END,
          resource_lock_partition, resource_database_id,
          resource_associated_entity_id
    FROM  sys.dm_tran_locks)
INSERT @locks_takeone(session_id, req_mode, rsc_type, rsc_subtype, req_status,
                      req_owner_type, rsc_description,
                      database_id, entity_id,
                      lock_partition, cnt,
                      groupno)
   SELECT request_session_id, req_mode, rsc_type, rsc_subtype, req_status,
          req_owner_type, rsc_description,
          resource_database_id, resource_associated_entity_id,
          resource_lock_partition, COUNT(*),
          rank() OVER(ORDER BY
                 request_session_id, req_mode, rsc_type, rsc_subtype, req_status,
                 req_owner_type, rsc_description,
                 resource_database_id, resource_associated_entity_id)
   FROM   CTE
   GROUP  BY request_session_id, req_mode, rsc_type, rsc_subtype, req_status,
          req_owner_type, rsc_description, resource_database_id,
          resource_associated_entity_id, resource_lock_partition

-----------------------------------------------------------------------
-- Mark processes with locks as active, and delete uninteresing processes.
-- We can skip this if @allprocesses is 2.
-----------------------------------------------------------------------
IF @allprocesses < 2
BEGIN
   IF @debug = 1
   BEGIN
      SELECT @ms = datediff(ms, @now, sysdatetime())
      RAISERROR ('Final decision on active processes %d ms.', 0, 1, @ms) WITH NOWAIT
   END

   UPDATE @procs
   SET    activity_level = 0
   FROM   @procs p
   WHERE  EXISTS (SELECT *
                  FROM   @locks_takeone l
                  WHERE  l.session_id = p.session_id
                    AND  l.activelock = 1)

   DELETE @procs WHERE activity_level > @allprocesses
END

------------------------------------------------------------------------
-- Get input buffers. Note that we can only find one per session, even if
-- a session has several requests.
------------------------------------------------------------------------
IF @debug = 1
BEGIN
   SELECT @ms = datediff(ms, @now, sysdatetime())
   RAISERROR ('Getting input buffers, time %d ms.', 0, 1, @ms) WITH NOWAIT
END

DECLARE C1 CURSOR FAST_FORWARD LOCAL FOR
   SELECT DISTINCT session_id
   FROM   @procs
   WHERE  is_user_process = 1
     AND  session_id > 0
OPEN C1

WHILE 1 = 1
BEGIN
   FETCH C1 INTO @spid
   IF @@fetch_status <> 0
      BREAK

   BEGIN TRY
      INSERT @inputbuffer(eventtype, params, inputbuffer)
         EXEC sp_executesql N'DBCC INPUTBUFFER (@spid) WITH NO_INFOMSGS',
                            N'@spid int', @spid

      UPDATE @inputbuffer
      SET    spid = @spid,
             inputbuffer = replace(inputbuffer COLLATE Latin1_General_BIN2,
                                   nchar(0), '')
      WHERE  ident = scope_identity()
   END TRY
   BEGIN CATCH
      INSERT @inputbuffer(inputbuffer, spid)
         VALUES('Error getting inputbuffer: ' + error_message(), @spid)
   END CATCH
END


DEALLOCATE C1

----------------------------------------------------------------------
-- Get the query text. This is not done in the main query, as we could
-- be blocked if someone is creating an SP and executes it in a
-- transaction.
----------------------------------------------------------------------
IF @debug = 1
BEGIN
   SELECT @ms = datediff(ms, @now, sysdatetime())
   RAISERROR ('Retrieving current statement, time %d ms.', 0, 1, @ms) WITH NOWAIT
END

-- Set lock timeout to avoid being blocked.
SET LOCK_TIMEOUT 5

-- First try to get all query plans in one go.
BEGIN TRY
   UPDATE @procs
   SET    curdbid      = est.dbid,
          curobjid     = est.objectid,
          current_stmt =
          CASE WHEN est.encrypted = 1
               THEN '-- ENCRYPTED, pos ' +
                    ltrim(str((p.stmt_start + 2)/2)) + ' - ' +
                    ltrim(str((p.stmt_end + 2)/2))
               WHEN p.stmt_start >= 0
               THEN substring(est.text, (p.stmt_start + 2)/2,
                              CASE p.stmt_end
                                   WHEN -1 THEN datalength(est.text)
                                 ELSE (p.stmt_end - p.stmt_start + 2) / 2
                              END)
          END
   FROM   @procs p
   CROSS  APPLY sys.dm_exec_sql_text(p.sql_handle) est
END TRY
BEGIN CATCH
   -- If this fails, try to get the texts one by one.
   DECLARE text_cur CURSOR STATIC LOCAL FOR
      SELECT DISTINCT session_id, request_id, sql_handle,
                      stmt_start, stmt_end
      FROM   @procs
      WHERE  sql_handle IS NOT NULL
   OPEN text_cur

   WHILE 1 = 1
   BEGIN
      FETCH text_cur INTO @spid, @request_id, @handle,
                          @stmt_start, @stmt_end
      IF @@fetch_status <> 0
         BREAK

      BEGIN TRY
         UPDATE @procs
         SET    curdbid      = est.dbid,
                curobjid     = est.objectid,
                current_stmt =
                CASE WHEN est.encrypted = 1
                     THEN '-- ENCRYPTED, pos ' +
                          ltrim(str((p.stmt_start + 2)/2)) + ' - ' +
                          ltrim(str((p.stmt_end + 2)/2))
                     WHEN p.stmt_start >= 0
                     THEN substring(est.text, (p.stmt_start + 2)/2,
                                    CASE p.stmt_end
                                         WHEN -1 THEN datalength(est.text)
                                       ELSE (p.stmt_end - p.stmt_start + 2) / 2
                                    END)
                END
         FROM   @procs p
         CROSS  APPLY sys.dm_exec_sql_text(p.sql_handle) est
         WHERE  p.session_id = @spid
           AND  p.request_id = @request_id
      END TRY
      BEGIN CATCH
          UPDATE @procs
          SET    current_stmt = 'ERROR: *** ' + error_message() + ' ***'
          WHERE  session_id = @spid
            AND  request_id = @request_id
      END CATCH
   END

   DEALLOCATE text_cur

   END CATCH

SET LOCK_TIMEOUT -1


--------------------------------------------------------------------
-- Get query plans. The difficult part is that the convert to xml may
-- fail if the plan is too deep. Therefore we catch this error, and
-- resort to a cursor in this case. Since query plans are not included
-- in text mode, we skip in that case.
--------------------------------------------------------------------
IF @textmode = 0
BEGIN
   IF @debug = 1
   BEGIN
      SELECT @ms = datediff(ms, @now, sysdatetime())
      RAISERROR ('Retrieving query plans, time %d ms.', 0, 1, @ms) WITH NOWAIT
   END

   -- Adam says that getting the query plans can time out too...
   SET LOCK_TIMEOUT 5

   BEGIN TRY
      UPDATE @procs
      SET    current_plan = convert(xml, etqp.query_plan)
      FROM   @procs p
      OUTER  APPLY sys.dm_exec_text_query_plan(
                   p.plan_handle, p.stmt_start, p.stmt_end) etqp
      WHERE  p.plan_handle IS NOT NULL
   END TRY
   BEGIN CATCH
      DECLARE plan_cur CURSOR STATIC LOCAL FOR
         SELECT DISTINCT session_id, request_id, plan_handle,
                         stmt_start, stmt_end
         FROM   @procs
         WHERE  plan_handle IS NOT NULL
      OPEN plan_cur

      WHILE 1 = 1
      BEGIN
         FETCH plan_cur INTO @spid, @request_id, @handle,
                             @stmt_start, @stmt_end
         IF @@fetch_status <> 0
            BREAK

         BEGIN TRY
            UPDATE @procs
            SET    current_plan = (SELECT convert(xml, etqp.query_plan)
                                   FROM   sys.dm_exec_text_query_plan(
                                      @handle, @stmt_start, @stmt_end) etqp)
            FROM   @procs p
            WHERE  p.session_id = @spid
              AND  p.request_id = @request_id
         END TRY
         BEGIN CATCH
            UPDATE @procs
            SET    current_plan =
                     (SELECT 'Could not get query plan' AS [@alert],
                             error_number() AS [@errno],
                             error_severity() AS [@level],
                             error_message() AS [@errmsg]
                      FOR    XML PATH('ERROR'))
            WHERE  session_id = @spid
              AND  request_id = @request_id
         END CATCH
      END

      DEALLOCATE plan_cur
   END CATCH

   SET LOCK_TIMEOUT -1
END

----------------------------------------------------------------------
-- Now we reduce @locks_takeone to @locks_final by aggregating the lock
-- partition into a string.
----------------------------------------------------------------------
IF @debug = 1
BEGIN
   SELECT @ms = datediff(ms, @now, sysdatetime())
   RAISERROR ('Aggregating out lock partitions, time %d ms.', 0, 1, @ms) WITH NOWAIT
END

-- Aggregate the counts on group number only, and then look up the
-- dependent attributes with an CROSS APPLY later. This is more efficient
-- than aggregating on the lot.
; WITH aggr AS (
   SELECT groupno, SUM(cnt) AS cnt
   FROM   @locks_takeone
   GROUP  BY groupno
)
INSERT @locks_final (groupno, session_id, req_mode, rsc_type, rsc_subtype,
                     req_status, req_owner_type, rsc_description,
                     database_id, entity_id, min_entity_id, cnt,
                     lock_partitions)
   SELECT a.groupno, b.session_id, b.req_mode, b.rsc_type, b.rsc_subtype,
          b.req_status, b.req_owner_type, b.rsc_description,
          b.database_id, b.entity_id, b.entity_id, a.cnt,
          CASE WHEN lp.lock_partitions = '0' THEN ''
               ELSE rtrim(lp.lock_partitions)
          END
   FROM   aggr a
   CROSS  APPLY  (SELECT TOP 1 b.session_id, b.req_mode, b.rsc_type, b.rsc_subtype,
                               b.req_status, b.req_owner_type, b.rsc_description,
                               b.database_id, b.entity_id, b.activelock
                 FROM    @locks_takeone b
                 WHERE   a.groupno = b.groupno
                 ORDER BY lock_partition) AS b
   OUTER APPLY
      -- Here we format the lock partitions in ranges where possible. This
      -- is a nice exercise in LEAD and LAG.
      (SELECT CASE WHEN lp.prev IS NULL
                   THEN lp.lpstr
                   WHEN lp.lock_partition - lp.prev > 1
                   THEN CASE WHEN lp.prev - lp.prevprev = 1
                             THEN '-' + ltrim(str(lp.prev))
                             ELSE ''
                        END + ' ' + lp.lpstr
                   WHEN lp.next IS NULL
                   THEN CASE WHEN lp.lock_partition - lp.prev = 1
                             THEN '-' + lp.lpstr
                             ELSE ''
                       END
              END AS [text()]
       FROM   (SELECT lt.lock_partition,
                      ltrim(str(lt.lock_partition)) as lpstr,
                      prev = LAG(lt.lock_partition)
                          OVER (ORDER BY lt.lock_partition),
                      prevprev = LAG(lt.lock_partition, 2)
                          OVER (ORDER BY lt.lock_partition),
                      next = LEAD(lt.lock_partition)
                          OVER (ORDER BY lt.lock_partition)
              FROM   @locks_takeone lt
              WHERE  a.groupno = lt.groupno) AS lp
       ORDER  BY lp.lock_partition
       FOR XML PATH('')) AS lp (lock_partitions)
   -- We take the occasion to filter out a few uninteresting locks. (The Sch-S
   -- locks on a database that also idle processes hold, and our own locks.
   WHERE  (b.activelock = 1 AND b.session_id <> @@spid) OR
          EXISTS (SELECT *
                  FROM   @procs p
                  WHERE  b.session_id = p.session_id)



-----------------------------------------------------------------------
-- Get object names from ids in @procs and @locks_final. You may think that
-- we could use object_name() and its second database parameter, but
-- object_name takes out a Sch-S lock (even with READ UNCOMMITTED) and
-- gets blocked if a object (read temp table) has been created in a transaction.
-----------------------------------------------------------------------
IF @debug = 1
BEGIN
   SELECT @ms = datediff(ms, @now, sysdatetime())
   RAISERROR ('Getting object names, time %d ms.', 0, 1, @ms) WITH NOWAIT
END

-- First get all entity ids into the temp table. And yes, do save them in
-- three columns. We translate the resource types to our own type, depending
-- on names are to be looked up. The session_id is only of interest in
-- tempdb and only for temp tables. We use MIN, since is the same data
-- appears for the same session_id, it cannot be a temp table.
INSERT #objects (idtype, database_id, entity_id, hobt_id, min_id, session_id)
   SELECT idtype, database_id, entity_id, entity_id, entity_id,
          CASE WHEN database_id = 2 THEN MIN(session_id) END
   FROM   (SELECT CASE WHEN rsc_type = 'OBJECT' THEN 'OBJ'
                       WHEN rsc_type IN ('PAGE', 'KEY', 'RID', 'HOBT') THEN 'HOBT'
                       WHEN rsc_type = 'ALLOCATION_UNIT' THEN 'AU'
                   END AS idtype,
                   database_id, entity_id, session_id
           FROM   @locks_final) AS l
   WHERE   idtype IS NOT NULL
   GROUP   BY idtype, database_id, entity_id
   UNION
   SELECT DISTINCT 'OBJ', curdbid, curobjid, curobjid, curobjid, NULL
   FROM   @procs
   WHERE  curdbid IS NOT NULL
     AND  curobjid IS NOT NULL

-- If the user does not have CONTROL SERVER, he may not be able to access all
-- databases. In this case, we save this to the table directly, rather than
-- handling it the error handler below (because else it destroys textmode).
IF NOT EXISTS (SELECT *
               FROM   sys.fn_my_permissions(NULL, NULL)
               WHERE  permission_name = 'CONTROL SERVER')
BEGIN
   UPDATE #objects
   SET    object_name = 'You do not have permissions to access the database ' +
                        quotename(db_name(database_id)) + '.'
   WHERE  has_dbaccess(db_name(database_id)) = 0
   OPTION (KEEPFIXED PLAN, MAXDOP 1)
END

-- Later there is a query where we read sys.partitions. Starting with SQL 2014
-- we get blocked when trying to retrive data about heaps that have been
-- created in an open transactions from this catalog view, despite that we
-- are using dirty reads. To not get stuck on these, we access sys.partitions
-- with READPAST and then use a fallback. READPAST is not permitted with
-- dirty reads, whence we also need READCOMMITTED. This is not an issue on
-- earlier versions.
SELECT @partition_hint =
       CASE WHEN @version >= '12'
            THEN ' WITH (READCOMMITTED, READPAST) '
            ELSE ''
       END

DECLARE C2 CURSOR STATIC LOCAL FOR
   SELECT DISTINCT str(database_id),
                   quotename(db_name(database_id))
   FROM   #objects
   WHERE  idtype IN  ('OBJ', 'HOBT', 'AU')
     AND  object_name IS NULL
   OPTION (KEEPFIXED PLAN, MAXDOP 1)

OPEN C2

WHILE 1 = 1
BEGIN
   FETCH C2 INTO @dbidstr, @dbname
   IF @@fetch_status <> 0
      BREAK

  -- This expression is used to for the object name. It looks differently
  -- in tempdb where we drop the unique parts of temp-tables.
  SELECT @objnameexpr =
         CASE @dbname
              WHEN '[tempdb]'
              THEN 'CASE WHEN len(o.name) = 9 AND
                           o.name LIKE "#" + replicate("[0-9A-F]", 8)
                      THEN "#(tblvar or dropped temp table)"
                      WHEN len(o.name) = 128 AND o.name LIKE "#[^#]%"
                      THEN substring(o.name, 1, charindex("_____", o.name) - 1)
                      ELSE db_name(@dbidstr) + "." +
                           coalesce(s.name + "." + o.name,
                                    "<" + ltrim(str(ob.entity_id)) + ">")
                   END'
              ELSE 'db_name(@dbidstr) + "." +
                           coalesce(s.name + "." + o.name,
                                    "<" + ltrim(str(ob.entity_id)) + ">")'
         END


   -- First handle allocation units. They bring us a hobt_id, or we go
   -- directly to the object when the container is a partition_id. We
   -- always get the type_desc. To make the dynamic SQL easier to read,
   -- we use some placeholders.
   SELECT @stmt = '
      UPDATE #objects
      SET    type_desc = au.type_desc,
             hobt_id   = CASE WHEN au.type IN (1, 3)
                              THEN au.container_id
                         END,
             idtype    = CASE WHEN au.type IN (1, 3)
                              THEN "HOBT"
                              ELSE "AU"
                         END,
             object_name = CASE WHEN au.type = 2 THEN  ' +
                              @objnameexpr + ' +
                              CASE WHEN p.index_id <= 1
                                   THEN ""
                                   ELSE "." + i.name
                              END +
                              CASE WHEN p.partition_number > 1
                                   THEN "(" +
                                         ltrim(str(p.partition_number)) +
                                        ")"
                                   ELSE ""
                              END
                              WHEN au.type = 0 THEN
                                 db_name(@dbidstr) + " (dropped table et al)"
                           END
      FROM   #objects ob
      JOIN   @dbname.sys.allocation_units au ON ob.entity_id = au.allocation_unit_id
      -- We should only go all the way from sys.partitions, for type = 3.
      LEFT   JOIN  (@dbname.sys.partitions p
                    JOIN    @dbname.sys.objects o ON p.object_id = o.object_id
                    JOIN    @dbname.sys.indexes i ON p.object_id = i.object_id
                                                 AND p.index_id  = i.index_id
                    JOIN    @dbname.sys.schemas s ON o.schema_id = s.schema_id)
         ON  au.container_id = p.partition_id
        AND  au.type = 2
      WHERE  ob.database_id = @dbidstr
        AND  ob.idtype = "AU"
      OPTION (KEEPFIXED PLAN, MAXDOP 1);
   '

   -- Now we can translate all hobt_id, including those we got from the
   -- allocation units.
   SELECT @stmt += '
      UPDATE #objects
      SET    object_name = ' + @objnameexpr + ' +
                           CASE WHEN p.index_id <= 1
                                THEN ""
                                ELSE "." + i.name
                           END +
                           CASE WHEN p.partition_number > 1
                                THEN "(" +
                                      ltrim(str(p.partition_number)) +
                                     ")"
                                ELSE ""
                           END + coalesce(" (" + ob.type_desc + ")", "")
      FROM   #objects ob
      JOIN   @dbname.sys.partitions p ' + @partition_hint + '
                                      ON ob.hobt_id  = p.hobt_id
      JOIN   @dbname.sys.objects o    ON p.object_id = o.object_id
      JOIN   @dbname.sys.indexes i    ON p.object_id = i.object_id
                                     AND p.index_id  = i.index_id
      JOIN   @dbname.sys.schemas s    ON o.schema_id = s.schema_id
      WHERE  ob.database_id = @dbidstr
        AND  ob.idtype = "HOBT"
      OPTION (KEEPFIXED PLAN, MAXDOP 1)
      '

   -- And now object ids, idtype = OBJ.
   SELECT @stmt += '
      UPDATE #objects
      SET    object_name = ' + @objnameexpr + '
      FROM   #objects ob
      LEFT   JOIN   (@dbname.sys.objects o
                     JOIN @dbname.sys.schemas s ON o.schema_id = s.schema_id)
             ON convert(int, ob.entity_id) = o.object_id
      WHERE  ob.database_id = @dbidstr
        AND  ob.idtype = "OBJ"
      OPTION (KEEPFIXED PLAN, MAXDOP 1)
   '

   -- Here is the fallback for locks in sys.partitions. Here we will pick
   -- up (temp) tables created in a transaction that have a clustered index,
   -- even if we can't get the heaps.
   IF @version >= '12'
   BEGIN
      -- First see if there are any HOBT rows in #objects where the name
      -- is missing at all.
      SELECT @stmt += '
         IF EXISTS (SELECT *
                    FROM   #objects
                    WHERE  database_id = @dbidstr
                      AND  idtype      = "HOBT"
                      AND  object_name IS NULL)
         BEGIN'

      -- If there is, try to the rows in sys.partitions one by one into
      -- a table variable by help of the object_id (which is what we
      -- have in entity_id for idtype = OBJ.)
      SELECT @stmt += '
            DECLARE @partitions TABLE
                    (object_id        int    NOT NULL,
                     index_id         int    NOT NULL,
                     partition_number int    NOT NULL,
                     hobt_id          bigint NOT NULL PRIMARY KEY)

            DECLARE @object_id int

            DECLARE part_cur CURSOR STATIC LOCAL FOR
               SELECT DISTINCT entity_id
               FROM   #objects
               WHERE  database_id = @dbidstr
                 AND  idtype = "OBJ"
               OPTION (KEEPFIXED PLAN, MAXDOP 1)

            OPEN part_cur

            WHILE 1 = 1
            BEGIN
               FETCH part_cur INTO @object_id
               IF @@fetch_status <> 0
                  BREAK

               BEGIN TRY
                  INSERT @partitions (object_id, index_id, partition_number,
                                      hobt_id)
                     SELECT @object_id, index_id, partition_number, hobt_id
                     FROM   @dbname.sys.partitions
                     WHERE  object_id = @object_id
               END TRY
               BEGIN CATCH
                  IF error_number() <> 1222
                     THROW
               END CATCH
            END

            DEALLOCATE part_cur
         '

      -- And how we can rerun the UPDATE above, but using the table
      -- variable instead.
      SELECT @stmt += '
            UPDATE #objects
            SET    object_name = ' + @objnameexpr + ' +
                                 CASE WHEN p.index_id <= 1
                                      THEN ""
                                      ELSE "." + i.name
                                 END +
                                 CASE WHEN p.partition_number > 1
                                      THEN "(" +
                                            ltrim(str(p.partition_number)) +
                                           ")"
                                      ELSE ""
                                 END + coalesce(" (" + ob.type_desc + ")", "")
            FROM   #objects ob
            JOIN   @partitions p            ON ob.hobt_id  = p.hobt_id
            JOIN   @dbname.sys.objects o    ON p.object_id = o.object_id
            JOIN   @dbname.sys.indexes i    ON p.object_id = i.object_id
                                           AND p.index_id  = i.index_id
            JOIN   @dbname.sys.schemas s    ON o.schema_id = s.schema_id
            WHERE  ob.database_id = @dbidstr
              AND  ob.idtype = "HOBT"
              AND  ob.object_name IS NULL
            OPTION (KEEPFIXED PLAN, MAXDOP 1)
         END
      '
   END

   -- Wrap the whole thing in TRY-CATCH so that we can capture any error.
   -- This is particularly important when we only have VIEW SERVER STATE,
   -- without being sysadmin or db_owner, reading from the system tables
   -- will block on non-committed objects.
   SELECT @stmt = ' BEGIN TRY
                       SET LOCK_TIMEOUT 5
                  ' + @stmt +
                  ' END TRY
                    BEGIN CATCH
                       UPDATE #objects
                       SET    object_name = "Error getting object name: " +
                                            error_message()
                       WHERE  database_id = @dbidstr
                         AND  object_name IS NULL
                    END CATCH
                  '

   -- Fix the placeholders.
   SELECT @stmt = replace(replace(replace(@stmt,
                         '"', ''''),
                         '@dbname', @dbname),
                         '@dbidstr', @dbidstr)

   --  And run the beast.
   -- PRINT @stmt
   EXEC (@stmt)
END
DEALLOCATE C2

-------------------------------------------------------------------
-- Consolidate temp tables, so that if a procedure has a lock on
-- several temp tables with the same name, it is only listed once.
-------------------------------------------------------------------
IF @debug = 1
BEGIN
   SELECT @ms = datediff(ms, @now, sysdatetime())
   RAISERROR ('Consolidating temp tables, time %d ms.', 0, 1, @ms) WITH NOWAIT
END

-- Count the temp tables, and find the lowest id in each group.
; WITH mintemp AS (
   SELECT object_name, session_id, idtype,
          MIN(entity_id) AS min_id, COUNT(*) AS cnt
   FROM   #objects
   WHERE  database_id = 2
     AND  object_name LIKE '#[^#]%'
   GROUP  BY object_name, session_id, idtype
   HAVING COUNT(*) > 1
)
UPDATE #objects
SET    min_id = m.min_id,
       cnt    = m.cnt,
       object_name = m.object_name + ' (x' + ltrim(str(m.cnt)) + ')'
FROM   #objects ob
JOIN   mintemp m ON m.object_name = ob.object_name
                AND m.idtype      = ob.idtype
                AND m.session_id  = ob.session_id
WHERE  ob.database_id = 2
OPTION (KEEPFIXED PLAN, MAXDOP 1)

SELECT @rowc = @@rowcount

IF @rowc > 0
BEGIN
   UPDATE @locks_final
   SET    min_entity_id  = ob.min_id,
          ismultipletemp = 1
   FROM   @locks_final  l
   JOIN   #objects ob ON l.database_id = ob.database_id
                     AND l.entity_id   = ob.entity_id
                     AND l.session_id  = ob.session_id
   WHERE  l.database_id = 2
     AND  ob.database_id = 2
     AND  ob.cnt > 1
   OPTION (KEEPFIXED PLAN)

   -- For these locks we don't care about lock partitioning.
   INSERT @locks_final (groupno,
                  session_id, req_mode, rsc_type, rsc_subtype,
                  req_status, req_owner_type, database_id, entity_id, cnt)
      SELECT -row_number() OVER(ORDER BY (SELECT NULL)),
             session_id, req_mode, rsc_type, rsc_subtype,
             req_status, req_owner_type, database_id, min_entity_id, SUM(cnt)
      FROM   @locks_final
      WHERE  ismultipletemp = 1
      GROUP  BY session_id, req_mode, rsc_type, rsc_subtype,
                req_status, req_owner_type, database_id, min_entity_id

   -- And delete the source locks
   DELETE @locks_final WHERE ismultipletemp = 1
END


-----------------------------------------------------------------------
-- Compute the blocking chain.
-----------------------------------------------------------------------
IF @debug = 1
BEGIN
   SELECT @ms = datediff(ms, @now, sysdatetime())
   RAISERROR ('Computing blocking chain, time %d ms.', 0, 1, @ms) WITH NOWAIT
END

-- Mark blockers that are waiting, that is waiting for something else
-- than another spid.
UPDATE @dm_os_waiting_tasks
SET    block_level = 0,
       lead_blocker_spid = a.wait_session_id
FROM   @dm_os_waiting_tasks a
WHERE  a.block_session_id IS NULL
  AND  EXISTS (SELECT *
               FROM   @dm_os_waiting_tasks b
               WHERE  a.wait_session_id = b.block_session_id
                 AND  a.wait_task       = b.block_task)
SELECT @rowc = @@rowcount

-- Add an extra row for blockers that are not waiting at all.
INSERT @dm_os_waiting_tasks (wait_session_id, wait_task,
                             block_level, lead_blocker_spid)
   SELECT DISTINCT a.block_session_id, coalesce(a.block_task, 0x),
                   0, a.block_session_id
   FROM   @dm_os_waiting_tasks a
   WHERE  NOT EXISTS (SELECT *
                      FROM  @dm_os_waiting_tasks b
                      WHERE a.block_session_id = b.wait_session_id
                        AND a.block_task       = b.wait_task)
     AND  a.block_session_id IS NOT NULL;

SELECT @rowc = @rowc + @@rowcount, @lvl = 0

-- Then iterate as long as we find blocked processes. You may think
-- that a recursive CTE would be great here, but we want to exclude
-- rows that has already been marked. This is difficult to do with a CTE.
WHILE @rowc > 0
BEGIN
   UPDATE a
   SET    block_level = b.block_level + 1,
          lead_blocker_spid = b.lead_blocker_spid
   FROM   @dm_os_waiting_tasks a
   JOIN   @dm_os_waiting_tasks b ON a.block_session_id = b.wait_session_id
                                AND a.block_task       = b.wait_task
   WHERE  b.block_level = @lvl
     AND  a.block_level IS NULL

  SELECT @rowc = @@rowcount, @lvl = @lvl + 1
END

-- Next to find are processes that are blocked, but no one is waiting for.
-- They are directly or indirectly blocked by a deadlock. They get a
-- negative level initially. We clean this up later.
UPDATE @dm_os_waiting_tasks
SET    block_level = -1
FROM   @dm_os_waiting_tasks a
WHERE  a.block_level IS NULL
  AND  a.block_session_id IS NOT NULL
  AND  NOT EXISTS (SELECT *
                   FROM   @dm_os_waiting_tasks b
                   WHERE  b.block_session_id = a.wait_session_id
                     AND  b.block_task       = a.wait_task)

SELECT @rowc = @@rowcount, @lvl = -2

-- Then unwind these chains in the opposite direction to before.
WHILE @rowc > 0
BEGIN
   UPDATE @dm_os_waiting_tasks
   SET    block_level = @lvl
   FROM   @dm_os_waiting_tasks a
   WHERE  a.block_level IS NULL
     AND  a.block_session_id IS NOT NULL
     AND  NOT EXISTS (SELECT *
                      FROM   @dm_os_waiting_tasks b
                      WHERE  b.block_session_id = a.wait_session_id
                        AND  b.block_task       = a.wait_task
                        AND  b.block_level IS NULL)
   SELECT @rowc = @@rowcount, @lvl = @lvl - 1
END

-- Determine which blocking tasks that only block tasks within the same
-- spid.
UPDATE @dm_os_waiting_tasks
SET    blocksamespidonly = 1
FROM   @dm_os_waiting_tasks a
WHERE  a.block_level IS NOT NULL
  AND  a.wait_session_id = a.lead_blocker_spid
  AND  NOT EXISTS (SELECT *
                   FROM   @dm_os_waiting_tasks b
                   WHERE  a.wait_session_id = b.lead_blocker_spid
                     AND  a.wait_session_id <> b.wait_session_id)

-----------------------------------------------------------------------
-- Add block-chain and wait information to @procs. If a blockee has more
-- than one blocker, we pick one.
-----------------------------------------------------------------------
IF @debug = 1
BEGIN
   SELECT @ms = datediff(ms, @now, sysdatetime())
   RAISERROR ('Adding blocking chain to @procs, time %d ms.', 0, 1, @ms) WITH NOWAIT
END

; WITH block_chain AS (
    SELECT wait_session_id, wait_task, block_session_id, block_task,
           block_level = CASE WHEN block_level >= 0 THEN block_level
                              ELSE block_level - @lvl - 1
                         END,
           wait_duration_ms, wait_type, blocksamespidonly,
           cnt   = COUNT(*) OVER (PARTITION BY wait_task),
           rowno = row_number() OVER (PARTITION BY wait_task
                                      ORDER BY block_level, block_task)
           FROM @dm_os_waiting_tasks
)
UPDATE p
SET    block_level           = bc.block_level,
       block_session_id      = bc.block_session_id,
       block_exec_context_id = coalesce(p2.exec_context_id, -1),
       block_request_id      = coalesce(p2.request_id, -1),
       blockercnt            = bc.cnt,
       blocksamespidonly     = bc.blocksamespidonly,
       wait_time             = convert(decimal(18, 3), bc.wait_duration_ms) / 1000,
       wait_type             = bc.wait_type
FROM   @procs p
JOIN   block_chain bc ON p.session_id   = bc.wait_session_id
                     AND p.task_address = bc.wait_task
                     AND bc.rowno = 1
LEFT   JOIN @procs p2 ON bc.block_session_id = p2.session_id
                     AND bc.block_task       = p2.task_address


--------------------------------------------------------------------
-- If user has selected to see process data only on the first row,
-- we should number the rows in @locks.
--------------------------------------------------------------------
IF @procdata = 'F'
BEGIN
   IF @debug = 1
   BEGIN
      SELECT @ms = datediff(ms, @now, sysdatetime())
      RAISERROR ('Determining first row, time %d ms.', 0, 1, @ms) WITH NOWAIT
   END

   ; WITH locks_lockno AS (
       SELECT lockno,
              new_lockno = row_number() OVER(PARTITION BY l.session_id
                           ORDER BY CASE l.req_status
                                         WHEN 'GRANT' THEN 'ZZZZ'
                                         ELSE l.req_status
                                   END,
                          o.object_name, l.rsc_type, l.rsc_description)
              FROM   @locks_final l
              LEFT   JOIN   #objects o ON l.database_id = o.database_id
                                      AND l.entity_id   = o.entity_id)
   UPDATE locks_lockno
   SET    lockno = new_lockno
   OPTION (KEEPFIXED PLAN, MAXDOP 1)
END

---------------------------------------------------------------------
-- Before we can join in the locks, we need to make sure that all
-- processes with a running request has a row with exec_context_id =
-- request_id = 0. (Those without already has such a row.)
---------------------------------------------------------------------
IF @debug = 1
BEGIN
   SELECT @ms = datediff(ms, @now, sysdatetime())
   RAISERROR ('Supplementing @procs, time %d ms.', 0, 1, @ms) WITH NOWAIT
END

INSERT @procs(session_id, task_address, exec_context_id, request_id,
              is_user_process, orig_login, current_login,
              session_state, endpoint_id, trancount, proc_dbid,
              host_name, host_process_id, program_name,
              session_cpu, session_physio, session_logreads,
              quoted_id, arithabort, ansi_null_dflt, ansi_defaults,
              ansi_warns, ansi_pad, ansi_nulls, concat_null,
              login_time, last_batch, last_since, procrowno)
   SELECT session_id, 0x, 0, 0,
          is_user_process, orig_login, current_login,
          session_state, endpoint_id, 0, proc_dbid,
          host_name, host_process_id, program_name,
          session_cpu, session_physio, session_logreads,
          quoted_id, arithabort, ansi_null_dflt, ansi_defaults,
          ansi_warns, ansi_pad, ansi_nulls, concat_null,
          login_time, last_batch, last_since, 0
    FROM  @procs a
    WHERE a.procrowno = 1
      AND NOT EXISTS (SELECT *
                      FROM   @procs b
                      WHERE  b.session_id      = a.session_id
                        AND  b.exec_context_id = 0
                        AND  b.request_id      = 0)

-- A process may be waiting for a lock according sys.dm_os_tran_locks,
-- but it was not in sys.dm_os_waiting_tasks. Let's mark this up.
UPDATE @procs
SET    waiter_no_blocker = 1
FROM   @procs p
WHERE  EXISTS (SELECT *
               FROM   @locks_final l
               WHERE  l.req_status = 'WAIT'
                 AND  l.session_id = p.session_id
                 AND  NOT EXISTS (SELECT *
                                  FROM   @procs p2
                                  WHERE  p.session_id = l.session_id))

------------------------------------------------------------------------
-- Let's produce the output.
------------------------------------------------------------------------
IF @debug = 1
BEGIN
   SELECT @ms = datediff(ms, @now, sysdatetime())
   RAISERROR ('Producing output table, time %d ms.', 0, 1, @ms) WITH NOWAIT
END

-- Note that the query is a full join, since @locks and @procs may not
-- be in sync. Processes may have gone away, or be active without any
-- locks. As for the transactions, we team up with the processes.
INSERT #output (spid, command, login, host, hostprc, endpoint, appl,
                dbname, prcstatus, ansiopts, spid_, trnopts, opntrn, trninfo,
                blklvl, blkby, cnt, object, rsctype, locktype, lstatus,
                ownertype, rscsubtype, waittime, waittype, spid__, cpu,
                physio, logreads, memgrant, progress, tempdb, now, login_time,
                last_batch, trn_start, last_since, trn_since, clr, nstlvl,
                spid___, inputbuffer, current_sp, curstmt, queryplan,
                rowno, spidnum)
SELECT spid        = coalesce(p.spidstr, ltrim(str(l.session_id))),
       command     = CASE WHEN coalesce(p.exec_context_id, 0) = 0 AND
                               coalesce(l.lockno, 1) = 1
                          THEN p.request_command
                          ELSE ''
                     END,
       login       = CASE WHEN coalesce(p.exec_context_id, 0) = 0 AND
                               coalesce(l.lockno, 1) = 1
                          THEN
                          CASE WHEN p.is_user_process = 0
                               THEN 'SYSTEM PROCESS'
                               ELSE p.orig_login +
                                  CASE WHEN p.current_login <> p.orig_login OR
                                            p.orig_login IS NULL
                                       THEN ' (' + rtrim(p.current_login) + ')'
                                       ELSE ''
                                  END
                         END
                         ELSE ''
                     END,
       host        = CASE WHEN coalesce(p.exec_context_id, 0)= 0 AND
                               coalesce(l.lockno, 1) = 1
                          THEN p.host_name
                          ELSE ''
                     END,
       hostprc     = CASE WHEN coalesce(p.exec_context_id, 0) = 0 AND
                               coalesce(l.lockno, 1) = 1
                          THEN ltrim(str(p.host_process_id))
                          ELSE ''
                     END,
       endpoint    = CASE WHEN coalesce(p.exec_context_id, 0) = 0 AND
                               coalesce(l.lockno, 1) = 1
                          THEN e.name
                          ELSE ''
                     END,
       appl        = CASE WHEN coalesce(p.exec_context_id, 0) = 0 AND
                               coalesce(l.lockno, 1) = 1
                          THEN p.program_name
                          ELSE ''
                     END,
       dbname      = CASE WHEN coalesce(l.lockno, 1) = 1 AND
                               coalesce(p.exec_context_id, 0) = 0
                          THEN coalesce(db_name(p.request_dbid),
                                        db_name(p.proc_dbid))
                          ELSE ''
                     END,
       prcstatus   = CASE WHEN coalesce(l.lockno, 1) = 1
                          THEN coalesce(p.task_state, p.session_state)
                          ELSE ''
                     END,
       ansiopts    = CASE WHEN coalesce(l.lockno, 1) = 1
                          THEN CASE WHEN p.quoted_id      = 0 THEN 'qid '   ELSE '' END +
                               CASE WHEN p.arithabort     = 1 THEN 'ARITH ' ELSE '' END +
                               CASE WHEN p.ansi_defaults  = 1 THEN 'ADEF '  ELSE '' END +
                               CASE WHEN p.ansi_null_dflt = 0 THEN 'ando '  ELSE '' END +
                               CASE WHEN p.ansi_warns     = 0 THEN 'awarn ' ELSE '' END +
                               CASE WHEN p.ansi_pad       = 0 THEN 'apad '  ELSE '' END +
                               CASE WHEN p.ansi_nulls     = 0 THEN 'anull ' ELSE '' END +
                               CASE WHEN p.concat_null    = 0 THEN 'cnyn '  ELSE '' END
                          ELSE ''
                     END,
       spid_       = p.spidstr,
       trnopts     = CASE WHEN coalesce(l.lockno, 1) = 1
                          THEN CASE p.isolation_lvl
                                    WHEN 0 THEN 'Unspecified  '
                                    WHEN 1 THEN 'Read uncommitted  '
                                    WHEN 2 THEN ''      -- This is the default, so no display.
                                    WHEN 3 THEN 'Repeatable read  '
                                    WHEN 4 THEN 'Serializable  '
                                    WHEN 5 THEN 'Snapshot  '
                                    ELSE 'Isolation level=' + ltrim(str(p.isolation_lvl)) + ' '
                              END +
                              CASE WHEN p.lock_timeout >= 0
                                    THEN 'LT=' + ltrim(str(p.lock_timeout)) + '  '
                                    ELSE ''
                              END +
                              CASE WHEN p.deadlock_pri <> 0
                                    THEN 'DP=' + ltrim(str(p.deadlock_pri))
                                    ELSE ''
                              END
                          ELSE ''
                     END,
       opntrn      = CASE WHEN p.exec_context_id = 0
                          THEN coalesce(ltrim(str(nullif(p.trancount, 0))), '')
                          ELSE ''
                     END,
       trninfo     = CASE WHEN coalesce(l.lockno, 1) = 1 AND
                               p.exec_context_id = 0 AND
                               t.is_user_trans IS NOT NULL
                          THEN CASE t.is_user_trans
                                    WHEN 1 THEN 'U'
                                    ELSE 'S'
                               END + '-' +
                               CASE t.trans_type
                                    WHEN 1 THEN 'RW'
                                    WHEN 2 THEN 'R'
                                    WHEN 3 THEN 'SYS'
                                    WHEN 4 THEN 'DIST'
                                    ELSE ltrim(str(t.trans_type))
                               END + '-' +
                               ltrim(str(t.trans_state)) +
                               CASE t.dtc_state
                                    WHEN 0 THEN ''
                                    ELSE '-'
                               END +
                               CASE t.dtc_state
                                  WHEN 0 THEN ''
                                  WHEN 1 THEN 'DTC:ACTIVE'
                                  WHEN 2 THEN 'DTC:PREPARED'
                                  WHEN 3 THEN 'DTC:COMMITED'
                                  WHEN 4 THEN 'DTC:ABORTED'
                                  WHEN 5 THEN 'DTC:RECOVERED'
                                  ELSE 'DTC:' + ltrim(str(t.dtc_state))
                              END +
                              CASE t.is_bound
                                 WHEN 0 THEN ''
                                 WHEN 1 THEN '-BND'
                              END
                         ELSE ''
                     END,
       blklvl      = CASE WHEN p.block_level IS NOT NULL
                          THEN CASE p.blocksamespidonly
                                    WHEN 1 THEN '('
                                    ELSE ''
                               END +
                               CASE WHEN p.block_level = 0
                                    THEN '!!'
                                    ELSE ltrim(str(p.block_level))
                               END +
                               CASE p.blocksamespidonly
                                    WHEN 1 THEN ')'
                                    ELSE ''
                               END
                          -- If the process is blocked, but we do not
                          -- have a block level, the process is in a
                          -- dead lock.
                          WHEN p.block_session_id IS NOT NULL
                          THEN 'DD'
                          WHEN p.waiter_no_blocker = 1
                          THEN '??'
                          ELSE ''
                     END,
       blkby       = coalesce(p.block_spidstr, ''),
       cnt         = CASE WHEN p.exec_context_id = 0 AND
                               p.request_id = 0
                          THEN coalesce(ltrim(str(l.cnt)), '0')
                          ELSE ''
                     END,
       object      = CASE l.rsc_type
                        WHEN 'APPLICATION'
                        THEN coalesce(db_name(l.database_id) + '|', '') +
                                      l.rsc_description
                        ELSE coalesce(o2.object_name,
                                      db_name(l.database_id), '')
                     END,
       rsctype     = coalesce(l.rsc_type, ''),
       locktype    = coalesce(l.req_mode, ''),
       lstatus     = CASE l.req_status
                          WHEN 'GRANT' THEN lower(l.req_status)
                          ELSE coalesce(l.req_status, '')
                     END,
       ownertype   = CASE l.req_owner_type
                          WHEN 'SHARED_TRANSACTION_WORKSPACE' THEN 'STW'
                          ELSE coalesce(l.req_owner_type, '')
                     END,
       rscsubtype  = coalesce(l.rsc_subtype, '') +
                     CASE WHEN len(l.lock_partitions) > 0
                          THEN CASE WHEN len(l.rsc_subtype) > 0
                                    THEN ' '
                                    ELSE ''
                               END + '[' + l.lock_partitions + ']'
                          ELSE ''
                     END,
       waittime    = CASE WHEN coalesce(l.lockno, 1) = 1
                          THEN coalesce(ltrim(str(p.wait_time, 18, 3)), '')
                          ELSE ''
                     END,
       waittype    = CASE WHEN coalesce(l.lockno, 1) = 1
                          THEN coalesce(p.wait_type, '')
                          ELSE ''
                     END,
       spid__      = p.spidstr,
       cpu         = CASE WHEN p.exec_context_id = 0 AND
                               coalesce(l.lockno, 1) = 1
                          THEN coalesce(ltrim(str(p.session_cpu)), '') +
                          CASE WHEN p.request_cpu IS NOT NULL
                               THEN ' (' + ltrim(str(p.request_cpu)) + ')'
                               ELSE ''
                          END
                          ELSE ''
                     END,
       physio      = CASE WHEN p.exec_context_id = 0 AND
                               coalesce(l.lockno, 1) = 1
                          THEN coalesce(ltrim(str(p.session_physio, 18)), '') +
                          CASE WHEN p.request_physio IS NOT NULL
                               THEN ' (' + ltrim(str(p.request_physio, 18)) + ')'
                               ELSE ''
                          END
                          ELSE ''
                     END,
       logreads    = CASE WHEN p.exec_context_id = 0 AND
                               coalesce(l.lockno, 1) = 1
                          THEN coalesce(ltrim(str(p.session_logreads, 18)), '')  +
                          CASE WHEN p.request_logreads IS NOT NULL
                               THEN ' (' + ltrim(str(p.request_logreads, 18)) + ')'
                               ELSE ''
                          END
                          ELSE ''
                     END,
       memgrant  = CASE WHEN coalesce(l.lockno, 1) = 1
                        THEN coalesce(ltrim(str(p.memory_grant, 18, 3)), '')
                        ELSE ''
                   END,
       progress  = CASE WHEN coalesce(l.lockno, 1) = 1
                        THEN coalesce(ltrim(str(p.percent_complete, 3)) + ' %', '')
                        ELSE ''
                   END,
       tempdb    = CASE WHEN p.exec_context_id = 0 AND
                               coalesce(l.lockno, 1) = 1
                          THEN coalesce(ltrim(str(p.session_tempdb, 18)), '')  +
                          CASE WHEN p.request_tempdb IS NOT NULL
                               THEN ' (' + ltrim(str(p.request_tempdb)) + ')'
                               ELSE ''
                          END
                          ELSE ''
                     END,
       now         = CASE WHEN p.exec_context_id = 0 AND
                                  coalesce(l.lockno, 1) = 1
                             THEN convert(char(12), @now, 114)
                             ELSE ''
                     END,
       login_time  = CASE WHEN p.exec_context_id = 0 AND
                               coalesce(l.lockno, 1) = 1
                          THEN
                          CASE datediff(DAY, p.login_time, @now)
                               WHEN 0
                               THEN convert(varchar(8), p.login_time, 8)
                               ELSE convert(char(7), p.login_time, 12) +
                                    convert(varchar(8), p.login_time, 8)
                          END
                          ELSE ''
                     END,
       last_batch  = CASE WHEN p.exec_context_id = 0 AND
                               coalesce(l.lockno, 1) = 1
                          THEN
                          CASE datediff(DAY, p.last_batch, @now)
                               WHEN 0
                               THEN convert(varchar(8), p.last_batch, 8)
                               ELSE convert(char(7), p.last_batch, 12) +
                                    convert(varchar(8), p.last_batch, 8)
                          END
                          ELSE ''
                     END,
       trn_start   = CASE WHEN p.exec_context_id = 0 AND
                               coalesce(l.lockno, 1) = 1 AND
                               t.trans_start IS NOT NULL
                          THEN
                          CASE datediff(DAY, t.trans_start, @now)
                               WHEN 0
                               THEN convert(varchar(8),
                                            t.trans_start, 8)
                               ELSE convert(char(7), t.trans_start, 12) +
                                    convert(varchar(8), t.trans_start, 8)
                          END
                          ELSE ''
                     END,
       last_since  = CASE WHEN p.exec_context_id = 0 AND
                               coalesce(l.lockno, 1) = 1
                          THEN
                          CASE WHEN p.last_since < 0
                               THEN str(p.last_since, 17, 3)
                               ELSE
                               CASE WHEN p.last_since >= 86400
                                    THEN str(convert(int, p.last_since) / 86400, 4)
                                    ELSE space(4)
                               END +
                               space(CASE WHEN p.last_since >= 36000 THEN 1
                                          WHEN p.last_since >=  3600 THEN 2
                                          WHEN p.last_since >=   600 THEN 4
                                          WHEN p.last_since >=    60 THEN 5
                                          WHEN p.last_since >=    10 THEN 7
                                          ELSE                            8
                                    END) +
                               substring(convert(char(8), dateadd(SECOND, p.last_since, '19000101'), 108),
                                         CASE WHEN p.last_since >= 36000 THEN 1
                                              WHEN p.last_since >=  3600 THEN 2
                                              WHEN p.last_since >=   600 THEN 4
                                              WHEN p.last_since >=    60 THEN 5
                                              WHEN p.last_since >=    10 THEN 7
                                              ELSE                            8
                                         END, 8) +
                               substring(str(p.last_since % 1, 5, 3), 2, 4)
                          END
                          ELSE ''
                     END,
       trn_since   = CASE WHEN p.exec_context_id = 0 AND
                               coalesce(l.lockno, 1) = 1 AND
                               t.trans_since IS NOT NULL
                          THEN CASE WHEN t.trans_since < 0
                                    THEN str(t.trans_since, 17, 3)
                               ELSE
                               CASE WHEN t.trans_since >= 86400
                                    THEN str(convert(int, t.trans_since) / 86400, 4)
                                    ELSE space(4)
                               END +
                               space(CASE WHEN t.trans_since >= 36000 THEN 1
                                          WHEN t.trans_since >=  3600 THEN 2
                                          WHEN t.trans_since >=   600 THEN 4
                                          WHEN t.trans_since >=    60 THEN 5
                                          WHEN t.trans_since >=    10 THEN 7
                                          ELSE                             8
                                    END) +
                               substring(convert(char(8), dateadd(SECOND, t.trans_since, '19000101'), 108),
                                         CASE WHEN t.trans_since >= 36000 THEN 1
                                              WHEN t.trans_since >=  3600 THEN 2
                                              WHEN t.trans_since >=   600 THEN 4
                                              WHEN t.trans_since >=    60 THEN 5
                                              WHEN t.trans_since >=    10 THEN 7
                                              ELSE                             8
                                         END, 8) +
                               substring(str(t.trans_since % 1, 5, 3), 2, 4)
                          END
                          ELSE ''
                     END,
       clr         = CASE WHEN p.exec_context_id = 0 AND p.isclr = 1
                          THEN 'CLR'
                          ELSE ''
                     END,
       nstlvl      = CASE WHEN p.exec_context_id = 0 AND
                               coalesce(l.lockno, 1) = 1
                          THEN coalesce(ltrim(str(p.nest_level)), '')
                          ELSE ''
                     END,
       spid___     = p.spidstr,
       inputbuffer = CASE WHEN p.exec_context_id = 0 AND
                               coalesce(l.lockno, 1) = 1
                          THEN coalesce(i.inputbuffer, '')
                          ELSE ''
                     END,
       current_sp  = coalesce(o1.object_name, ''),
       curstmt     = CASE WHEN coalesce(l.lockno, 1) = 1
                          THEN coalesce(p.current_stmt, '')
                          ELSE coalesce(substring(
                                     p.current_stmt, 1, 50), '')
                     END,
       current_plan = CASE WHEN p.exec_context_id = 0 AND
                                coalesce(l.lockno, 1) = 1
                           THEN p.current_plan
                      END,
       rowno        = row_number() OVER(ORDER BY
                         coalesce(p.session_id, l.session_id),
                         p.exec_context_id,
                         coalesce(nullif(p.request_id, 0), 99999999),
                         l.lockno,
                         CASE l.req_status
                            WHEN 'GRANT' THEN lower(l.req_status)
                            ELSE coalesce(l.req_status, '')
                         END,
                         coalesce(o2.object_name, db_name(l.database_id)),
                         l.rsc_type, l.rsc_description),
       spidnum       =  coalesce(p.session_id, l.session_id)
FROM   @procs p
LEFT   JOIN #objects o1 ON p.curdbid  = o1.database_id
                       AND p.curobjid = o1.entity_id
LEFT   JOIN @inputbuffer i ON p.session_id = i.spid
                          AND p.exec_context_id = 0
LEFT   JOIN sys.endpoints e ON p.endpoint_id = e.endpoint_id
LEFT   JOIN @transactions t ON t.session_id = p.session_id
FULL   JOIN (@locks_final AS l
              LEFT JOIN #objects o2 ON l.database_id = o2.database_id
                                   AND l.entity_id   = o2.entity_id)
  ON    p.session_id      = l.session_id
 AND    p.exec_context_id = 0
 AND    p.request_id      = 0
OPTION (KEEPFIXED PLAN, MAXDOP 1)

-- If regular output requested, produce that now.
IF @textmode = 0 AND @archivemode IS NULL
BEGIN
   -- We return all columns but two, rowno and spidnum which are helper
   -- column for archive and text mode.
   SELECT spid, command, login, host, hostprc, endpoint, appl,
          dbname, prcstatus, ansiopts, spid_, trnopts, opntrn, trninfo,
          blklvl, blkby, cnt, object, rsctype, locktype, lstatus,
          ownertype, rscsubtype, waittime, waittype, spid__, cpu,
          physio, logreads, memgrant, progress, tempdb, now, login_time,
          last_batch, trn_start, last_since, trn_since, clr, nstlvl,
          spid___, inputbuffer, current_sp, curstmt, queryplan
    FROM  #output
    ORDER BY rowno

    RETURN
END

------------------------------------------------------------------------
-- Here we do text mode where we fit the column witdhs carefully.
------------------------------------------------------------------------
IF @textmode = 1
BEGIN
   IF @debug = 1
   BEGIN
      SELECT @ms = datediff(ms, @now, sysdatetime())
      RAISERROR ('Producing output for text mode, time %d ms.', 0, 1, @ms) WITH NOWAIT
   END

   -- For textmode we want to mark the last row for every spid, so we can add a
   -- blank line there.
   UPDATE #output
   SET    spidnum = 0
   FROM   #output this
   WHERE  EXISTS (SELECT *
                  FROM   #output next
                  WHERE  next.rowno = this.rowno + 1
                    AND  next.spidnum <> this.spidnum)
   OPTION (KEEPFIXED PLAN, MAXDOP 1)

   -- Local varibles for the max lengths of all columns.
   DECLARE @spidlen        varchar(5),
           @commandlen     varchar(5),
           @loginlen       varchar(5),
           @hostlen        varchar(5),
           @hostprclen     varchar(5),
           @endpointlen    varchar(5),
           @appllen        varchar(5),
           @dbnamelen      varchar(5),
           @prcstatuslen   varchar(5),
           @ansioptlen     varchar(5),
           @trnoptlen      varchar(5),
           @opntrnlen      varchar(5),
           @trninfolen     varchar(5),
           @blklvllen      varchar(5),
           @blkbylen       varchar(5),
           @cntlen         varchar(5),
           @objectlen      varchar(5),
           @rsctypelen     varchar(5),
           @locktypelen    varchar(5),
           @lstatuslen     varchar(5),
           @ownertypelen   varchar(5),
           @rscsubtypelen  varchar(5),
           @waittimelen    varchar(5),
           @waittypelen    varchar(5),
           @cpulen         varchar(5),
           @physiolen      varchar(5),
           @logreadslen    varchar(5),
           @memgrantlen    varchar(5),
           @progresslen    varchar(5),
           @tempdblen      varchar(5),
           @login_timelen  varchar(5),
           @last_batchlen  varchar(5),
           @trn_startlen   varchar(5),
           @last_sincelen  varchar(5),
           @trn_sincelen   varchar(5),
           @inputbufferlen varchar(5),
           @current_splen  varchar(5)


   -- Remove line breaks in current statement and inputbuffer.
   UPDATE #output
   SET    curstmt = replace(replace(curstmt, char(10), ''), char(13), '')
   WHERE  len(curstmt) > 0
   OPTION (KEEPFIXED PLAN, MAXDOP 1)

   UPDATE #output
   SET    inputbuffer = replace(replace(inputbuffer, char(10), ''), char(13), '')
   WHERE  len(inputbuffer) > 0
   OPTION (KEEPFIXED PLAN, MAXDOP 1)

   -- Get all maxlengths
   SELECT @spidlen        = convert(varchar(5), coalesce(nullif(max(coalesce(len(spid), 4)), 0), 1)),
          @commandlen     = convert(varchar(5), coalesce(nullif(max(coalesce(len(command), 4)), 0), 1)),
          @loginlen       = convert(varchar(5), coalesce(nullif(max(coalesce(len(login), 4)), 0), 1)),
          @hostlen        = convert(varchar(5), coalesce(nullif(max(coalesce(len(host), 4)), 0), 1)),
          @hostprclen     = convert(varchar(5), coalesce(nullif(max(coalesce(len(hostprc), 4)), 0), 1)),
          @endpointlen    = convert(varchar(5), coalesce(nullif(max(coalesce(len(endpoint), 4)), 0), 1)),
          @appllen        = convert(varchar(5), coalesce(nullif(max(coalesce(len(appl), 4)), 0), 1)),
          @dbnamelen      = convert(varchar(5), coalesce(nullif(max(coalesce(len(dbname), 4)), 0), 1)),
          @prcstatuslen   = convert(varchar(5), coalesce(nullif(max(coalesce(len(prcstatus), 4)), 0), 1)),
          @ansioptlen     = convert(varchar(5), coalesce(nullif(max(coalesce(len(ansiopts), 4)), 0), 1)),
          @trnoptlen      = convert(varchar(5), coalesce(nullif(max(coalesce(len(trnopts), 4)), 0), 1)),
          @opntrnlen      = convert(varchar(5), coalesce(nullif(max(coalesce(len(opntrn), 4)), 0), 1)),
          @trninfolen     = convert(varchar(5), coalesce(nullif(max(coalesce(len(trninfo), 4)), 0), 1)),
          @blklvllen      = convert(varchar(5), coalesce(nullif(max(coalesce(len(blklvl), 4)), 0), 1)),
          @blkbylen       = convert(varchar(5), coalesce(nullif(max(coalesce(len(blkby), 4)), 0), 1)),
          @cntlen         = convert(varchar(5), coalesce(nullif(max(coalesce(len(cnt), 4)), 0), 1)),
          @objectlen      = convert(varchar(5), coalesce(nullif(max(coalesce(len(object), 4)), 0), 1)),
          @rsctypelen     = convert(varchar(5), coalesce(nullif(max(coalesce(len(rsctype), 4)), 0), 1)),
          @locktypelen    = convert(varchar(5), coalesce(nullif(max(coalesce(len(locktype), 4)), 0), 1)),
          @lstatuslen     = convert(varchar(5), coalesce(nullif(max(coalesce(len(lstatus), 4)), 0), 1)),
          @ownertypelen   = convert(varchar(5), coalesce(nullif(max(coalesce(len(ownertype), 4)), 0), 1)),
          @rscsubtypelen  = convert(varchar(5), coalesce(nullif(max(coalesce(len(rscsubtype), 4)), 0), 1)),
          @waittimelen    = convert(varchar(5), coalesce(nullif(max(coalesce(len(waittime), 4)), 0), 1)),
          @waittypelen    = convert(varchar(5), coalesce(nullif(max(coalesce(len(waittype), 4)), 0), 1)),
          @cpulen         = convert(varchar(5), coalesce(nullif(max(coalesce(len(cpu), 4)), 0), 1)),
          @physiolen      = convert(varchar(5), coalesce(nullif(max(coalesce(len(physio), 4)), 0), 1)),
          @memgrantlen    = convert(varchar(5), coalesce(nullif(max(coalesce(len(memgrant), 4)), 0), 1)),
          @logreadslen    = convert(varchar(5), coalesce(nullif(max(coalesce(len(logreads), 4)), 0), 1)),
          @progresslen    = convert(varchar(5), coalesce(nullif(max(coalesce(len(progress), 4)), 0), 1)),
          @tempdblen      = convert(varchar(5), coalesce(nullif(max(coalesce(len(tempdb), 4)), 0), 1)),
          @login_timelen  = convert(varchar(5), coalesce(nullif(max(coalesce(len(login_time), 4)), 0), 1)),
          @last_batchlen  = convert(varchar(5), coalesce(nullif(max(coalesce(len(last_batch), 4)), 0), 1)),
          @trn_startlen   = convert(varchar(5), coalesce(nullif(max(coalesce(len(trn_start), 4)), 0), 1)),
          @last_sincelen  = convert(varchar(5), coalesce(nullif(max(coalesce(len(ltrim(last_since)), 4)), 0), 1)),
          @trn_sincelen   = convert(varchar(5), coalesce(nullif(max(coalesce(len(ltrim(trn_since)), 4)), 0), 1)),
          @inputbufferlen = convert(varchar(5), coalesce(nullif(max(coalesce(len(inputbuffer), 4)), 0), 1)),
          @current_splen  = convert(varchar(5), coalesce(nullif(max(coalesce(len(current_sp), 4)), 0), 1))
   FROM   #output
   OPTION (KEEPFIXED PLAN, MAXDOP 1)

   -- Return the #output table with dynamic lengths.
   IF @debug = 1
   BEGIN
      SELECT @ms = datediff(ms, @now, sysdatetime())
      RAISERROR ('Returning result set, time %d ms.', 0, 1, @ms) WITH NOWAIT
   END

   EXEC ('SELECT spid        = convert(varchar( ' + @spidlen + '), spid),
                 command     = convert(varchar( ' + @commandlen + '), command),
                 login       = convert(nvarchar( ' + @loginlen + '), login),
                 host        = convert(nvarchar( ' + @hostlen + '), host),
                 hostprc     = convert(varchar( ' + @hostprclen + '), hostprc),
                 endpoint    = convert(varchar( ' + @endpointlen + '), endpoint),
                 appl        = convert(nvarchar( ' + @appllen + '), appl),
                 dbname      = convert(nvarchar( ' + @dbnamelen + '), dbname),
                 prcstatus   = convert(varchar( ' + @prcstatuslen + '), prcstatus),
                 ansiopts    = convert(varchar( ' + @ansioptlen + '), ansiopts),
                 spid_       = convert(varchar( ' + @spidlen + '), spid),
                 trnopts     = convert(varchar( ' + @trnoptlen + '), trnopts),
                 opntrn      = convert(varchar( ' + @opntrnlen + '), opntrn),
                 trninfo     = convert(varchar( ' + @trninfolen + '), trninfo),
                 blklvl      = convert(varchar( ' + @blklvllen + '), blklvl),
                 blkby       = convert(varchar( ' + @blkbylen + '), blkby),
                 cnt         = convert(varchar( ' + @cntlen + '), cnt),
                 object      = convert(nvarchar( ' + @objectlen + '), object),
                 rsctype     = convert(varchar( ' + @rsctypelen + '), rsctype),
                 locktype    = convert(varchar( ' + @locktypelen + '), locktype),
                 lstatus     = convert(varchar( ' + @lstatuslen + '), lstatus),
                 ownertype   = convert(varchar( ' + @ownertypelen + '), ownertype),
                 rscsubtype  = convert(varchar( ' + @rscsubtypelen + '), rscsubtype),
                 waittime    = convert(varchar( ' + @waittimelen + '), waittime),
                 waittype    = convert(varchar( ' + @waittypelen + '), waittype),
                 spid__      = convert(varchar( ' + @spidlen + '), spid),
                 cpu         = convert(varchar( ' + @cpulen + '), cpu),
                 physio      = convert(varchar( ' + @physiolen + '), physio),
                 logreads    = convert(varchar( ' + @logreadslen + '), logreads),
                 memgrant    = convert(varchar( ' + @memgrantlen + '), progress),
                 progress    = convert(varchar( ' + @progresslen + '), progress),
                 tempdb      = convert(varchar( ' + @tempdblen + '), tempdb),
                 now,
                 login_time  = convert(varchar( ' + @login_timelen + '), login_time),
                 last_batch  = convert(varchar( ' + @last_batchlen + '), last_batch),
                 trn_start   = convert(varchar( ' + @trn_startlen + '), trn_start),
                 last_since  = convert(varchar( ' + @last_sincelen + '), ltrim(last_since)),
                 trn_since   = convert(varchar( ' + @trn_sincelen + '), ltrim(trn_since)),
                 clr,
                 nstlvl,
                 spid___     = convert(varchar( ' + @spidlen + '), spid),
                 inputbuffer = convert(nvarchar( ' + @inputbufferlen + '), inputbuffer),
                 current_sp  = convert(nvarchar( ' + @current_splen + '), current_sp),
                 curstmt,
                 CASE spidnum WHEN 0 THEN char(10) ELSE '' '' END
          FROM   #output
          ORDER  BY rowno')

          RETURN
END

----------------------------------------------------------------------------
-- Archive mode. We save data to guest.beta_lockinfo which we create if
-- needed.
----------------------------------------------------------------------------
do_archive:
IF @archivemode <= 0 AND object_id('guest.beta_lockinfo') IS NOT NULL
   DROP TABLE guest.beta_lockinfo
IF object_id('guest.beta_lockinfo') IS NULL
BEGIN
   IF @debug = 1
   BEGIN
      SELECT @ms = datediff(ms, @now, sysdatetime())
      RAISERROR ('Writing data to archive table, time %d ms.', 0, 1, @ms) WITH NOWAIT
   END

   -- The table is very similar to the #output table, but there are a few small
   -- diferences.
   CREATE TABLE guest.beta_lockinfo(
       spid        varchar(30)    COLLATE Latin1_General_BIN2 NOT NULL,
       command     nvarchar(32)   COLLATE Latin1_General_BIN2 NULL,
       login       nvarchar(260)  COLLATE Latin1_General_BIN2 NULL,
       host        nvarchar(128)  COLLATE Latin1_General_BIN2 NULL,
       hostprc     varchar(10)    COLLATE Latin1_General_BIN2 NULL,
       endpoint    sysname        COLLATE Latin1_General_BIN2 NULL,
       appl        nvarchar(128)  COLLATE Latin1_General_BIN2 NULL,
       dbname      sysname        COLLATE Latin1_General_BIN2 NULL,
       prcstatus   nvarchar(60)   COLLATE Latin1_General_BIN2 NULL,
       ansiopts    varchar(50)    COLLATE Latin1_General_BIN2 NULL,
       spid_       varchar(30)    COLLATE Latin1_General_BIN2 NULL,
       trnopts     varchar(60)    COLLATE Latin1_General_BIN2 NULL,
       opntrn      varchar(10)    COLLATE Latin1_General_BIN2 NULL,
       trninfo     varchar(60)    COLLATE Latin1_General_BIN2 NULL,
       blklvl      varchar(10)    COLLATE Latin1_General_BIN2 NOT NULL,
       blkby       varchar(30)    COLLATE Latin1_General_BIN2 NOT NULL,
       cnt         varchar(10)    COLLATE Latin1_General_BIN2 NOT NULL,
       object      nvarchar(550)  COLLATE Latin1_General_BIN2 NULL,
       rsctype     nvarchar(60)   COLLATE Latin1_General_BIN2 NOT NULL,
       locktype    nvarchar(60)   COLLATE Latin1_General_BIN2 NOT NULL,
       lstatus     nvarchar(60)   COLLATE Latin1_General_BIN2 NOT NULL,
       ownertype   nvarchar(60)   COLLATE Latin1_General_BIN2 NOT NULL,
       rscsubtype  varchar(1100)  COLLATE Latin1_General_BIN2 NOT NULL,
       waittime    varchar(19)    COLLATE Latin1_General_BIN2 NULL,
       waittype    nvarchar(60)   COLLATE Latin1_General_BIN2 NULL,
       spid__      varchar(30)    COLLATE Latin1_General_BIN2 NULL,
       cpu         varchar(25)    COLLATE Latin1_General_BIN2 NULL,
       physio      varchar(40)    COLLATE Latin1_General_BIN2 NULL,
       logreads    varchar(40)    COLLATE Latin1_General_BIN2 NULL,
       memgrant    varchar(19)    COLLATE Latin1_General_BIN2 NULL,
       progress    varchar(5)     COLLATE Latin1_General_BIN2 NULL,
       tempdb      varchar(40)    COLLATE Latin1_General_BIN2 NULL,
       now         datetime2(3)   NOT NULL,
       login_time  varchar(16)    COLLATE Latin1_General_BIN2 NULL,
       last_batch  varchar(16)    COLLATE Latin1_General_BIN2 NULL,
       trn_start   varchar(16)    COLLATE Latin1_General_BIN2 NULL,
       last_since  varchar(17)    COLLATE Latin1_General_BIN2 NULL,
       trn_since   varchar(17)    COLLATE Latin1_General_BIN2 NULL,
       clr         char(3)        COLLATE Latin1_General_BIN2 NULL,
       nstlvl      char(3)        COLLATE Latin1_General_BIN2 NULL,
       spid___     varchar(30)    COLLATE Latin1_General_BIN2 NULL,
       inputbuffer nvarchar(4000) COLLATE Latin1_General_BIN2 NULL,
       current_sp  nvarchar(400)  COLLATE Latin1_General_BIN2 NULL,
       curstmt     nvarchar(MAX)  COLLATE Latin1_General_BIN2 NULL,
       queryplan   xml            NULL,
       rowno       int            NOT NULL,
       CONSTRAINT beta_lockinfo_pk PRIMARY KEY (now, rowno)
    )
    -- Exit if we were to only create the table.
    IF @archivemode <= 0 RETURN
END

-- Delete old data in the table as requested.
DELETE guest.beta_lockinfo
WHERE  now < dateadd(MINUTE, -@archivemode, @now)

-- Copy the data from #output. Note that the for the "now" column we the
-- variable to have a value on all rows.
INSERT guest.beta_lockinfo
   SELECT spid, command, login, host, hostprc, endpoint, appl,
          dbname, prcstatus, ansiopts, spid_, trnopts, opntrn, trninfo,
          blklvl, blkby, cnt, object, rsctype, locktype, lstatus,
          ownertype, rscsubtype, waittime, waittype, spid__, cpu,
          physio, logreads, memgrant, progress, tempdb, @now, login_time,
          last_batch, trn_start, last_since, trn_since, clr, nstlvl,
          spid___, inputbuffer, current_sp, curstmt, queryplan,
          rowno
   FROM   #output
   UNION ALL
-- Add a delimiter row to mark the end (And which will show up, even if
-- #output is empty.)
   SELECT '*****', '*****', '*****', '*****', '*****', '*****', '*****',
          '*****', '*****', '*****', '*****', '*****', '*****', '*****',
          '*****', '*****', '*****', '*****', '*****', '*****', '*****',
          '*****', '*****', '*****', '*****', '*****', '*****',
          '*****', '*****', '*****', '*****', '*****', @now, '*****',
          '*****', '*****', '*****', '*****', '***', '***',
          '*****', '*****', '*****', '*****', NULL,
          coalesce(MAX(rowno), 0) + 1
   FROM   #output
