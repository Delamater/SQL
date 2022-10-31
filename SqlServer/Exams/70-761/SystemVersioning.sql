CREATE TABLE dbo.Student 
(    
    [StudentID] INT NOT NULL PRIMARY KEY CLUSTERED   
  , [FirstName] VARCHAR(100) NOT NULL  
  , [LastName] VARCHAR(100) NOT NULL   
  , [CreditHours] INT NOT NULL  
  , [ValidFrom] DATETIME2 (2) GENERATED ALWAYS AS ROW START  
  , [ValidTo] DATETIME2 (2) GENERATED ALWAYS AS ROW END  
  , PERIOD FOR SYSTEM_TIME (ValidFrom, ValidTo)  
 )    
 WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.StudentHistory));

INSERT INTO Student(StudentID, FirstName, LastName, CreditHours)
VALUES (1,'Tim', 'Brown',5),
         (2,'Lisa', 'Edwin',10),
         (3,'Mike', 'Green',9),
         (4,'Erica', 'James',7)

 SELECT * FROM Student   
    FOR SYSTEM_TIME    
        BETWEEN '2016-07-29 00:00:00.0000000' AND '9999-07-29 00:00:00.0000000'   
            WHERE StudentID = 2 --ORDER BY ValidFrom; 


UPDATE Student
SET CreditHours = 12
WHERE StudentID = 4;

DELETE Student WHERE StudentID = 4;

SELECT * FROM StudentHistory


-- Cleanup
alter table Student set (system_versioning = off)
drop table Student, StudentHistory