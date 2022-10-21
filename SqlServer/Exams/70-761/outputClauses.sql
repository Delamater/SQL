CREATE TABLE EmpDetails (
EmpID int PRIMARY KEY, 
EmpName varchar(30),
HireDate datetime, 
DeptID int, 
JobID int);

create sequence dbo.EmpID START WITH 1 INCREMENT BY 1

alter sequence dbo.EmpID restart with 1;
insert into EmpDetails 
output INSERTED.*
SELECT 
	(NEXT VALUE FOR dbo.EmpID),SUBSTRING(CAST(NEWID() AS VARCHAR(MAX)),1,10), GETDATE(), 1, 1
from sys.columns CROSS JOIN (SELECT TOP 10 * from sys.tables) a



select * from EmpDetails
Where 
	EmpName = 'A01E1648-F' 
	AND JobID = 1 
	And DeptID = 1 
	AND EmpID = 46015
order by EmpName, JobID, DeptID
create index ixCover1 ON EmpDetails(EmpName, DeptID, JobID)
create index ixCover2 ON EmpDetails(EmpID, EmpName, DeptID, JobID)
create index ixCover3 ON EmpDetails(EmpName, DeptID, JobID, EmpID)

drop index EmpDetails.ixCover1, EmpDetails.ixCover2, EmpDetails.ixCover3


drop table EmpDetails
delete EmpDetails
output deleted.EmpID
select count(*)FROM EmpDetails

