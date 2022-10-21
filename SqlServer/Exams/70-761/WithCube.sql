create table Customer
(
	CustomerID INT NULL,
	TerritoryID INT NOT NULL,
	AccountNumber INT NULL,
	CustomerType NCHAR(1) NOT NULL,
	rowguidid UNIQUEIDENTIFIER NOT NULL,
	ModifiedDate DATETIME NOT NULL
)

insert into Customer
select 
	(next value for EmpID), -- CustomerID
	ABS(CHECKSUM(NEWID()) %4), -- territory id
	ABS(CHECKSUM(NEWID()) %3), -- AccountNumber
	(SELECT 1+ CONVERT(INT, (4-1+1)*RAND())), -- Customer Type (1-4 random number)
	NEWID(), --rowguidid
	(select cast(cast(RAND()*100000 as int) as datetime)) -- modifieddate
from sys.columns, sys.tables

SELECT TerritoryID, CustomerType, COUNT(CustomerID) AS CustCount
FROM Customer
GROUP BY TerritoryID, CustomerType WITH CUBE;

SELECT TerritoryID, CustomerType, COUNT(CustomerID) AS CustCount
FROM Customer
GROUP BY TerritoryID, CustomerType WITH ROLLUP;

select count(*)
from Customer
where 
	TerritoryID = 0
	CustomerType = 1

