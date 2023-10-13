#requires -Modules SqlServer

enum ServiceAction {
    Stop
    Start
}

enum SessionState{
    START
    STOP
}

function Set-Services{
    param(
        [Parameter(Mandatory = $true)] [System.Object][ValidateNotNullOrEmpty()]$config,
        [Parameter(Mandatory = $true)] [ServiceAction]$action
    )

    if($action -eq [ServiceAction]::Start){
        $config.services | ForEach-Object { 
            Write-Host "Starting service $_" -ForegroundColor DarkBlue
            Get-Service -DisplayName $_ | Start-Service 
        }
    }elseif($action -eq [ServiceAction]::Stop){
        $config.services | ForEach-Object{
            Write-Host "Stopping service $_" -ForegroundColor DarkBlue
            Get-Service -DisplayName $_ | Stop-Service
        }        
    }else{
        throw "Service Action not implemented yet: $action"
    }
}

function KillProcesses {
    param(
        [Parameter(Mandatory=$true)]
        $process_names
    )

    $process_names | ForEach-Object {
        $processes = Get-Process -Name $_ -ErrorAction Ignore
        if ($processes) {
            $processes | ForEach-Object {
                Write-Host "Killing process ProcessName: $($_.Name) | ID: $($_.Id)" -ForegroundColor DarkYellow
                Stop-Process -Id $_.Id -Force
            }
        } else {
            Write-Host "No matching processes found for $_" -ForegroundColor DarkRed
        }
    }
}


function PromptRegistryKeyValue{
    $choices = '&Empty', '&False', '&None'
    $decision = $Host.UI.PromptForChoice("Set USE_SQL_FAST Value", "Choose...", $choices, 0)
    return $decision
}

function Set-ExtendedEventSession{
    param(
        [Parameter(Mandatory=$true)]$config,
        [Parameter(Mandatory=$true)][SessionState]$session_state,
        [Parameter(Mandatory=$true)][string]$extended_event_session_name
    )

    $query = "ALTER EVENT SESSION [$extended_event_session_name] ON SERVER STATE = $($session_state)"
    Invoke-Sqlcmd -ServerInstance $config.ServerInstance -Username $config.db_user -Password $config.db_password -Query $query -OutputSqlErrors $true -AbortOnError 
    
}

function Set-RegistryKeyValue{
    param(
        [Parameter(Mandatory = $true)]$decision
    )

    $registry_path = "HKLM:\SOFTWARE\Adonix\X3RUNTIME\X3ERPV12RUN"
    $registry_key = "USE_SQL_FAST1"


    switch ($decision) {
        0 {  Set-ItemProperty -Path $registry_path -Name $registry_key -Value ""}
        1 {  Set-ItemProperty -Path $registry_path -Name $registry_key -Value "FALSE"}
        2 {  Set-ItemProperty -Path $registry_path -Name $registry_key -Value "NONE"}
        Default {}
    }

    $reg_key_value = (Get-ItemProperty -Path $registry_path).$registry_key
    Write-Host "Registry Key Value: $($reg_key_value)" -ForegroundColor DarkBlue
}

function Get-ExtendedEventSessionName{
    param(
        [Parameter(Mandatory=$true)][int][ValidateRange(0,2)]$decision
    )

    $extended_event_session_name = "Performance Data FAST"

    switch ($decision) {
        0 { return "$($extended_event_session_name) DEFAULT" }
        1 { return "$($extended_event_session_name) FALSE" }
        2 { return "$($extended_event_session_name) NONE" }
    }

    throw "Unexpected code path"
}

try {
    # Stop service
    [object]$config = Get-Content -Path (Join-Path -Path $PSScriptRoot -ChildPath "TestConfig.config") | ConvertFrom-Json

    Set-Services -config $config -action Stop

    # Kill adonix and sadoss
    KillProcesses -process_names $config.process_names

    # Set registry value
    $decision = PromptRegistryKeyValue 
    $extended_event_session_name = Get-ExtendedEventSessionName -decision $decision
    Set-RegistryKeyValue -decision $decision 

    # Start extended event
    Set-ExtendedEventSession -config $config -extended_event_session_name $extended_event_session_name -session_state Start

    # Start service
    Set-Services -config $config -action Start

    Write-Host "Perform your X3 actions, and don't forget to turn off the session" -ForegroundColor DarkGreen
}
catch {
    Write-Error $_
}
finally {
    Write-Host "Procedure complete" -ForegroundColor DarkYellow
}