-- Database: dbtest

-- DROP DATABASE dbtest;

CREATE DATABASE dbtest
    WITH 
    OWNER = unicorn_user
    ENCODING = 'LATIN1'
    LC_COLLATE = 'C'
    LC_CTYPE = 'C'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1;

ALTER DATABASE dbtest
    SET default_transaction_isolation TO 'read committed';