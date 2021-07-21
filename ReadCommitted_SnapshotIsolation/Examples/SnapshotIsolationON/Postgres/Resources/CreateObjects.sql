CREATE SCHEMA RESEARCH;
CREATE SEQUENCE RESEARCH.SEQ_EMPLOYEE START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE RESEARCH.SEQ_JOB START WITH 1 INCREMENT BY 1;
CREATE TABLE RESEARCH.EMPLOYEE
(
        ID INT NOT NULL PRIMARY KEY, JOBID INT NULL, FNAME VARCHAR(100) NOT NULL, LNAME VARCHAR(100) NOT NULL, 
        SOCIAL_SECURITY VARCHAR(100) NOT NULL, LongText TEXT NULL
);

CREATE TABLE RESEARCH.JOB
(
        ID INT PRIMARY KEY NOT NULL, JOB_NAME VARCHAR(100), 
        LongText TEXT
);