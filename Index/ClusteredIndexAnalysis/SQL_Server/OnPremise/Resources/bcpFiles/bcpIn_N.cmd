SET NumberOfRows=50000
bcp clusteredIndexAnalysis.RESEARCH.EMPLOYEE IN EMPLOYEE.dat -S 127.0.0.1 -U SA -P yourStrong(!)Password -n -F 1 -L %NumberOfRows%
bcp clusteredIndexAnalysis.RESEARCH.EMPLOYEE_NC IN EMPLOYEE_NC.dat -S 127.0.0.1 -U SA -P yourStrong(!)Password -n -F 1 -L %NumberOfRows%
bcp clusteredIndexAnalysis.RESEARCH.EMPLOYEE_GUID IN EMPLOYEE_GUID.dat -S 127.0.0.1 -U SA -P yourStrong(!)Password -n -F 1 -L %NumberOfRows%
bcp clusteredIndexAnalysis.RESEARCH.EMPLOYEE_GUID_NC IN EMPLOYEE_GUID_NC.dat -S 127.0.0.1 -U SA -P yourStrong(!)Password -n -F 1 -L %NumberOfRows%
bcp clusteredIndexAnalysis.RESEARCH.EMPLOYEE_GUID_ORDERED IN EMPLOYEE_GUID_ORDERED.dat -S 127.0.0.1 -U SA -P yourStrong(!)Password -n -F 1 -L %NumberOfRows%
bcp clusteredIndexAnalysis.RESEARCH.EMPLOYEE_GUID_ORDERED_NC IN EMPLOYEE_GUID_ORDERED_NC.dat -S 127.0.0.1 -U SA -P yourStrong(!)Password -n -F 1 -L %NumberOfRows%
bcp clusteredIndexAnalysis.RESEARCH.JOB IN JOB.dat -S 127.0.0.1 -U SA -P yourStrong(!)Password -n -F 1 -L %NumberOfRows%
bcp clusteredIndexAnalysis.RESEARCH.JOB_NC IN JOB_NC.dat -S 127.0.0.1 -U SA -P yourStrong(!)Password -n -F 1 -L %NumberOfRows%

sqlcmd -S . -U sa -P "yourStrong(!)Password" -Q "SELECT (select count(*) from clusteredIndexAnalysis.RESEARCH.EMPLOYEE WITH(NOLOCK)) EMPLOYEE, (select count(*) from clusteredIndexAnalysis.RESEARCH.EMPLOYEE_NC WITH(NOLOCK)) EMPLOYEE_NC, (select count(*) from clusteredIndexAnalysis.RESEARCH.EMPLOYEE_GUID WITH(NOLOCK)) EMPLOYEE_GUID, (select count(*) from clusteredIndexAnalysis.RESEARCH.EMPLOYEE_GUID_NC WITH(NOLOCK)) EMPLOYEE_GUID_NC"

pause