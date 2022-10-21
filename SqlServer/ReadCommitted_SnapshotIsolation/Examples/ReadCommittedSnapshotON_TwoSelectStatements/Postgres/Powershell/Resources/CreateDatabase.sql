CREATE DATABASE dbtest
    WITH 
    OWNER = unicorn_user
    TEMPLATE = template0
    ENCODING = 'LATIN1'
    LC_COLLATE = 'en_US.utf8'
    LC_CTYPE = 'en_US.utf8'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1;

ALTER DATABASE dbtest
    SET default_transaction_isolation TO 'read committed';