
<#PSScriptInfo

.VERSION 1.0

.GUID a0dc7994-c825-45fc-a3b2-3ad68e541dc6

.AUTHOR Bob Delamater

.COMPANYNAME

.COPYRIGHT

.TAGS MemoryOptimizedTables

.LICENSEURI

.PROJECTURI

.ICONURI

.EXTERNALMODULEDEPENDENCIES 

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES


.PRIVATEDATA

#>

#Requires -Module SqlServer

<# 

.DESCRIPTION 
 Part of a multi-script example for testing memory optimized tables using various connection string properties 

#> 
Param()

Import-Module .\sql_statements.ps1 -Force

try {
    [string]$cnn = "Data Source=127.0.0.1,1433;Initial Catalog=TestDB;UID=sa;PWD=yourStrong(!)Password;"
    $sql = Get-SqlStatements
    Invoke-Sqlcmd -ConnectionString $cnn -Query $sql.Update2
    
}
catch {
    Write-Error $_
}
finally {
    Write-Host "Procedure Complete" -ForegroundColor DarkYellow 
}