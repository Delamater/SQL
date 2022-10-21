CREATE TABLE Reservations (
ID int IDENTITY (1,1) NOT NULL,
CustomerID int NOT NULL,
ArrivalDate datetime NOT NULL,
DepartDate datetime NOT NULL,
TotalAmount money NOT NULL,
DepositAmount AS TotalAmount * .15);

DECLARE @tblvar table (
ID int NOT NULL, 
CustomerID int NOT NULL,
TotalAmount money NOT NULL);

INSERT INTO Reservations
OUTPUT 
	INSERTED.ID,
	INSERTED.CustomerID,
	INSERTED.TotalAmount
INTO @tblvar
OUTPUT INSERTED.*, GETDATE() 
VALUES (35, '11-10-08', '11-15-08', 400.00);

INSERT INTO Reservations
OUTPUT INSERTED.*, GETDATE() 
VALUES (35, '11-10-08', '11-15-08', 400.00);

select * from @tblvar