create table Title
(
	TitleID INT PRIMARY KEY IDENTITY(1,1),
	Title VARCHAR(MAX),
	PublisherID INT,
	Price Money,
	YearToDateSales Money
)

create table Publisher
(
	PublisherID INT PRIMARY KEY IDENTITY(1,1),
	Name VARCHAR(MAX),
	City VARCHAR(MAX),
	State CHAR(2),
	Country CHAR(3)
)


insert into Title
SELECT 
	newid(), 
	abs(checksum(newid()))%5, -- PublisherID
	(select 20 + convert(money,(50-.99+1))*rand()), --price
	(select 100 + convert(money,(50-.99+1))*rand()) --YearToDateSales
from sys.columns

insert into Publisher
values
	('Bob', 'Placentia', 'CA', 'USA'),
	('Joe', 'Jackson Hole', 'WY', 'USA'),
	('Michele', 'Paris', 'Au', 'FRA'),
	('Jean', 'Somewhere', 'Br', 'BRR')


select Name, City, State, Country, Sum(YearToDateSales) AS Total
from Title AS T
inner join Publisher as p
	On t.PublisherID = p.PublisherID
group by rollup(Country, State, City, Name)

-- same as
select Name, City, State, Country, Sum(YearToDateSales) AS Total
from Title AS T
inner join Publisher as p
	On t.PublisherID = p.PublisherID
group by Country,State,City,Name with rollup


-- same as
select 
	(CASE WHEN (GROUPING(Name) = 1) THEN 'TOTAL' ELSE Name END) AS Name, 
	Name, City, State, Country, Sum(YearToDateSales) AS Total
from Title AS T
inner join Publisher as p
	On t.PublisherID = p.PublisherID
group by grouping sets((Name, City, State, Country), (City, State, Country), (State, Country), (Country), ())


drop table Books, Publisher

