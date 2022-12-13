
<#PSScriptInfo

.VERSION 1.0

.GUID f9088db6-9d0b-462f-b501-7a8979c8a7b9

.AUTHOR Bob Delamater

.COMPANYNAME

.COPYRIGHT

.TAGS SqlServer

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
 Basic sql statement assets used for Connection1.ps1 and Connection2.ps1 test scripts 

#> 
Param()



function Get-SqlStatements{
    $create_table = (Get-Content -Path "E:\g\Delamater\SQL\SqlServer\Performance\Memory\MemoryOptimizedAssets\PowerShell\CreateTable.sql" -Force)
    [object]$sql = @{
        create_table = $create_table
        Update1 = "SELECT 'update1'"
        Update2 = "SELECT 'update2'"
    }

    return $sql
}


