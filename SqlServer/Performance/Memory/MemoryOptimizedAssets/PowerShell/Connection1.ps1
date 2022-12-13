
<#PSScriptInfo

.VERSION 1.0

.GUID b4e74b10-7823-4c74-9428-5f004a1660df

.AUTHOR Bob Delamater

.COMPANYNAME

.COPYRIGHT

.TAGS MemoryOptimizedTables

.LICENSEURI

.PROJECTURI

.ICONURI

.EXTERNALMODULEDEPENDENCIES 

.REQUIREDSCRIPTS
    sql_statements.ps1
    
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
    Invoke-Sqlcmd -ConnectionString $cnn -Query $sql.Update1
}
catch {
    Write-Error $_
}
finally {
    Write-Host "Procedure Complete" -ForegroundColor DarkYellow 
}