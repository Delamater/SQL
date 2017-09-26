BEGIN TRY
    BEGIN TRANSACTION 
          CREATE TABLE dbo.Computer 
             (ComputerID INT PRIMARY KEY NOT NULL, 
               ComputerName VARCHAR(100) NOT NULL, 
               Price MONEY NULL, 
               ComputerDescription VARCHAR(500) NULL) 
        PRINT 'Created table Computer'
          CREATE TABLE Production.Product 
             (ProductID INT PRIMARY KEY NOT NULL,  
               ProductName VARCHAR(100) NOT NULL,  
               Price MONEY NULL,  
               ProductDescription VARCHAR(500) NULL) 
          PRINT 'Created table Product'
    COMMIT
     PRINT 'Transaction committed'
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
     BEGIN
         PRINT 'Error in the transaction.'
        ROLLBACK
     END
END CATCH