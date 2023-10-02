#Requires -Version 7.2
#Requires -Modules SqlServer

$config = @{
    assets_folder               = "./Assets"
    create_table_tsql           = "create_table_my_sample_data.sql"
    get_record_count            = "get_record_count.sql"
    insert_table_tsql           = "insert_my_sample_data.sql"
    table_definition            = "get_table_definition.sql"
    db_user                     = "sa"
    db_password                 = "x3erpv12" 
    server_instance             = "."
    port                        = 1433
    database                    = "x3erpv12"


}

function Invoke-Sql{
    param(
        [Parameter(Mandatory=$true, ParameterSetName="InputFile")][string][ValidateNotNullOrEmpty()]$input_file,
        [Parameter(Mandatory=$true, ParameterSetName="DirectQuery")][string][ValidateNotNullOrEmpty()]$query,
        [Parameter(Mandatory=$true)][object]$my_config
    )

    if ($input_file){
        Invoke-Sqlcmd `
        -ServerInstance ($my_config.server_instance) `
        -Database ($my_config.database) `
        -Username ($my_config.db_user) `
        -Password ($my_config.db_password) `
        -OutputSqlErrors $true `
        -OutputAs DataRows `
        -InputFile $input_file 

    }elseif($query){
        Invoke-Sqlcmd `
        -ServerInstance ($my_config.server_instance) `
        -Database ($my_config.database) `
        -Username ($my_config.db_user) `
        -Password ($my_config.db_password) `
        -OutputSqlErrors $true `
        -OutputAs DataRows `
        -Query $query

    }
        
}

function Get-TableDefinition{
    param(
        [Parameter(Mandatory=$true)][string][ValidateNotNullOrEmpty()]$table_name,
        [Parameter(Mandatory=$true)][string][ValidateNotNullOrEmpty()]$schema_name,
        [Parameter(Mandatory=$true)][object][ValidateNotNullOrEmpty()]$myconfig
    )

    [string]$tsql = Get-Content -Path ($myconfig.table_definition).Path 
    $tsql = $tsql.Replace("##SCHEMA_NAME##", "SEED")
    $tsql = $tsql.Replace("##TABLE_NAME##", "QUREXTRACT")
    
    $drTableDefinition = Invoke-Sql -Query $tsql -my_config $myconfig -ErrorAction Stop 
    return $drTableDefinition
}

try {
    $config.db_password = Read-Host -Prompt "What is the db user's password?" 
    
    $config.create_table_tsql = Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath $config.assets_folder -AdditionalChildPath $config.create_table_tsql) -ErrorAction Stop
    $config.insert_table_tsql = Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath $config.assets_folder -AdditionalChildPath $config.insert_table_tsql) -ErrorAction Stop
    $config.get_record_count = Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath $config.assets_folder -AdditionalChildPath $config.get_record_count) -ErrorAction Stop
    $config.table_definition = Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath $config.assets_folder -AdditionalChildPath $config.table_definition) -ErrorAction Stop

    Invoke-Sql -input_file ($config.create_table_tsql).Path -my_config $config -ErrorAction Stop
    Invoke-Sql -input_file ($config.insert_table_tsql).Path -my_config $config -ErrorAction Stop
    $rec_count = Invoke-Sql -input_file ($config.get_record_count).Path -my_config $config -ErrorAction Stop
    Write-Host "Record Count $($rec_count.DataCount)" -ForegroundColor DarkYellow
    Get-TableDefinition -table_name "QUREXTRACT" -schema_name "SEED" -myconfig $config
}
catch {
    $_
}
finally {
    Write-Host "Procedure Complete" -ForegroundColor DarkYellow
}