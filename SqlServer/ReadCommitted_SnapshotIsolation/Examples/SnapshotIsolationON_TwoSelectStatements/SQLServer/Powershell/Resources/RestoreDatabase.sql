USE [master]
RESTORE DATABASE [x3erpv12] FROM  DISK = N'/data/x3v12.bak' WITH  FILE = 1,  MOVE N'x3erpv12_data' TO N'/var/opt/mssql/data/x3erpv12_data.mdf',  MOVE N'SEED_DAT' TO N'/var/opt/mssql/data/x3erpv12_SEED_DAT.ndf',  MOVE N'SEED_IDX' TO N'/var/opt/mssql/data/x3erpv12_SEED_IDX.ndf',  MOVE N'x3erpv12_log' TO N'/var/opt/mssql/data/x3erpv12_log.ldf',  NOUNLOAD,  STATS = 5

GO

