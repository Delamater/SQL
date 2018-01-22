exec sp_MSforeachtable @command1 = 'ALTER INDEX ALL ON ? REBUILD';
exec sp_MSforeachtable @command1 = 'ALTER TABLE ? REBUILD';
