-- Script 2 of 2: Logged in as BOB01
USE dbTest01
GO

EXEC sp_addrolemember 'X3_ADX', @membername = 'BOB01'
EXEC sp_droprolemember 'Production', @membername = 'BOB01'

sp_help sp_tableoption @TableNamePattern='SEED.BANK', @OptionName='table lock on bulk load', @OptionValue=1


USE [x3erpv12]
GO
ALTER ROLE [db_ddladmin] DROP MEMBER [SEED]
GO
create table SEED.tb1(ID INT)
sp_rename @objname = 'SEED.tb1', @newname = 'tb2'
sp_rename @objname = 'SEED.tb2', @newname = 'tb1'

select * from sys.tables order by create_date desc
select * from [SEED.tb2]

select * from SEED.tb1
drop table SEED.[SEED.tb1]