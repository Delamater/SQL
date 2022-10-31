-- https://docs.oracle.com/cd/B19306_01/server.102/b14200/statements_9004.htm
-- drops tablespace and drops all referential integrity constraints that refer to primary and unique keys inside user1_dat
DROP TABLESPACE user1_dat
    INCLUDING CONTENTS 
        CASCADE CONSTRAINTS; 


-- drops the user1_idx tablespace and deletes all associated operating system datafiles
DROP TABLESPACE user1_idx
    INCLUDING CONTENTS AND DATAFILES;
        