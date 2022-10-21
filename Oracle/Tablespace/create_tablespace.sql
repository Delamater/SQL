create tablespace user1_dat datafile 
        '/sql/data/tablespace1.dbf'
        size 1100M reuse
        autoextend on next 100M MAXSIZE unlimited 
        ; 
create tablespace user1_idx datafile 
        '/sql/data/tablespace2.dbf'
        size 500M reuse
        autoextend on next 50M MAXSIZE unlimited 
        ; 