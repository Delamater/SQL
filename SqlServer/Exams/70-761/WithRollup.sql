create table Employee
(EmpID INT NULL, [Name] varchar(100) null, Salary money null)

insert into Employee
select (next value for EmpID), NEWID(), abs(checksum(newid())) %81 * 2080
from sys.columns, sys.tables

SELECT 
	(CASE WHEN (GROUPING(Name) = 1) THEN 'TOTAL' ELSE Name END) AS Name, 
	Name,
	Salary, SUM(Salary) AS TotalSal 
FROM Employee 
GROUP BY Salary, Name WITH ROLLUP 
HAVING Salary < 100000 and Salary > 0

delete Employee

