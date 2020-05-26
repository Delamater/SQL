CREATE TABLE dbo.t1(ID INT PRIMARY KEY IDENTITY(1,1), fname NVARCHAR(100), lname NVARCHAR(100))

INSERT INTO dbo.t1(fname, lname) values('Bob', 'Delamater'), ('John', 'Doe')

ALTER TABLE dbo.t1 ADD StartTime DATETIME2
ALTER TABLE dbo.t1 ADD EndTime DATETIME2

UPDATE dbo.t1 SET StartTime = '19000101 00:00:00.0000000', EndTime = '99991231 23:59:59.9999999'

ALTER TABLE dbo.t1 ALTER COLUMN StartTime DATETIME2 NOT NULL
ALTER TABLE dbo.t1 ALTER COLUMN EndTime DATETIME2 NOT NULL
ALTER TABLE dbo.t1 ADD PERIOD FOR SYSTEM_TIME (StartTime, EndTime)
ALTER TABLE dbo.t1 SET (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.t1_history, DATA_CONSISTENCY_CHECK = ON))

SELECT * FROM dbo.t1
update dbo.t1
set lname = 'Cuervos'
where id = 2

update dbo.t1
set lname = 'Smith'
where id = 1

SELECT * FROM dbo.t1
select * from dbo.t1_history

ALTER TABLE dbo.t1
	SET (SYSTEM_VERSIONING = OFF (HISTORY_TABLE = dbo.t1_history))


drop table dbo.t1
