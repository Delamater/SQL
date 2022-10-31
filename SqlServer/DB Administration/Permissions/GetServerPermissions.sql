select * 
from master.sys.server_permissions 
where grantor_principal_id = SUSER_ID('sa')
