SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- ================================================ 
-- Author:      Eli Leiba         
-- Create date: 24-03-2019            
-- Description: Simple Users to Database Roles mappings function     
-- Example call: SELECT * FROM dbo.dbRolesUsersMap (DEFAULT)      
-- ================================================
CREATE FUNCTION dbo.dbRolesUsersMap (@dbRole SYSNAME = '%')
RETURNS TABLE
AS
RETURN (
      SELECT 
        User_Type = 
           CASE mmbrp.[type] 
           WHEN 'G' THEN 'Windows Group' 
           WHEN 'S' THEN 'SQL User' 
           WHEN 'U' THEN 'Windows User' 
           END,
         Database_User_Name = mmbrp.[name],
         Login_Name = ul.[name],
         DB_Role = rolp.[name]
      FROM sys.database_role_members mmbr, -- The Role OR members associations table
         sys.database_principals rolp,     -- The DB Roles names table
         sys.database_principals mmbrp,    -- The Role members table (database users)
         sys.server_principals ul          -- The Login accounts table
      WHERE Upper (mmbrp.[type]) IN ( 'S', 'U', 'G' )
         -- No need for these system account types
         AND Upper (mmbrp.[name]) NOT IN ('SYS','INFORMATION_SCHEMA')
         AND rolp.[principal_id] = mmbr.[role_principal_id]
         AND mmbrp.[principal_id] = mmbr.[member_principal_id]
         AND ul.[sid] = mmbrp.[sid]
         AND rolp.[name] LIKE '%' + @dbRole + '%'
      )
GO