INSERT INTO RESEARCH.EMPLOYEE(ID, JOBID, FNAME, LNAME, SOCIAL_SECURITY, LongText)
SELECT nextval('RESEARCH.SEQ_EMPLOYEE'), NULL, 'Bob', 'Delamater', 'my social security', 'Some long text here' from pg_catalog.pg_aggregate 
LIMIT 10