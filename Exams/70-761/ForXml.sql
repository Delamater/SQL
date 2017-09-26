create table Students
(
	StudentID INT IDENTITY(1,1),
	ProgramID INT,
	SSN VARCHAR(MAX),
	Name VARCHAR(MAX),
	Email VARCHAR(MAX),
	Address VARCHAR(MAX),
	City VARCHAR(MAX),
	State CHAR(2),
	ZipCode INT,
	GPA DECIMAL(16,2),
	GradYear INT
)

CREATE TABLE Program
(
	ProgramID INT IDENTITY(1,1),
	DeptID INT,
	Title VARCHAR(MAX)
)

insert into students
select 
	abs(checksum(newid())) %3 + 1, -- program id
	abs(checksum(newid())), --ssn
	newid(), --name
	newid(), --email
	newid(), --address
	newid(), --city
	substring(cast(newid() as varchar(max)),1,2), --state
	abs(checksum(newid()))%99999+1, -- zipcode
	cast(abs(checksum(newid()))%5 as decimal(4,2)) + cast((abs(checksum(newid()))%101 * .01) as float), -- gpa
	(select 2017 + convert(int,(2021-2017+1)*rand())) --Gradyear
from sys.columns

insert into Program
values (1, 'Music'), (2,'Economics'), (3, 'Liberal Arts')


select * from Students 


select 
	StudentID AS '@ID', 
	Title AS '@Program',
	Email AS 'EmailAddress',
	GPA AS 'Info/GPA',
	GradYear AS 'Info/Year'
from Program
inner join Students on Program.ProgramID = Students.ProgramID
where Title = 'Music' 
FOR XML PATH('Student'), ROOT('Students')

select 
	StudentID , 
	Title,
	Email,
	GPA,
	GradYear
from Program
inner join Students on Program.ProgramID = Students.ProgramID
where Title = 'Music' 
FOR XML auto

select 
	StudentID , 
	Title,
	Email,
	GPA,
	GradYear
from Program
inner join Students on Program.ProgramID = Students.ProgramID
where Title = 'Music' 
FOR XML auto, elements

--drop table Students, Program
