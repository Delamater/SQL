CREATE ROLE SEEDOL8_ADX;
grant
        create session,
        create table,
        create view,
        create trigger,
        create sequence,
        create procedure,
        alter session
        to SEEDOL8_ADX ;
revoke SEEDOL8_ADX from system;