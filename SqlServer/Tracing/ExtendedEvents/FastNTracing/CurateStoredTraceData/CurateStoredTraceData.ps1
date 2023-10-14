#requires -Modules SqlServer

param(
    [switch]$install_extended_events
)

enum Step{
    Step1
    Step2
    Step3
}

# Define the steps descriptions
$stepDescriptions = [ordered]@{
    Step1                   = "Step1 Desc"
    Step2                   = "Step2 Desc"
    Step3                   = "Step3 Desc"
}

enum Status{
    NotStarted
    InProgress
    Completed
}

enum LogMessageType{
    Info
    Warning
    Error
    Debug
}

function Register-ExtendedEvents{

}

function Get-Config{
    param(
        [Parameter(Mandatory=$true)][string]$file_path
    )

    return Get-Content -Path $file_path | ConvertFrom-Json
}

function Install-ExtendedEventTraces{
    param(
        [Parameter(Mandatory=$true)]$config,
        [Parameter(Mandatory=$true)][string]$trace_definitions_path
    )

    $traces = $config.ExtendedEventsTraces | ForEach-Object{
        (Join-Path -Path $trace_definitions_path -ChildPath $_)
    }
    
    $traces | ForEach-Object{
        $result = Execute-QueryFile -config $config -queryFile $_ -OutputAs DataRows 
        Write-Host $result -ForegroundColor DarkYellow
    }

}

function Get-ExtendedEventData{
    param(
        [parameter(Mandatory=$true)]$config,
        [parameter(Mandatory=$true)][string]$table_or_view,
        [parameter(Mandatory=$true)][string]$output_file
    )

    return Execute-Query -config $config -query "SELECT TOP 100 * FROM $table_or_view" -OutputAs DataTables 
}

function Convert-ExportToExcelWorkbook{
    param(
        [Parameter(Mandatory=$true)]$output_file
    )
    # Convert CSV to Excel
    $dir_to_file = (Get-Item -Path $output_file).Directory.BaseName
    $file_name = (Get-Item -Path $output_file).BaseName
    $excel_path = (Join-Path -Path $dir_to_file -ChildPath "$($file_name).xlsx" )
    $excel = New-Object -ComObject Excel.application
    $excel.Visible = $false
    $workbook = $excel.Workbooks.Add()
    $worksheet = $workbook.Worksheets.Item(1)
    $worksheet.Name = "SQL Results"
    $csv_content = Import-Csv -Path $output_file
    $worksheet.Cells.Item(1,1).LoadFromText($csv_content, $excel.CsvDelimeter)
    $workbook.SaveAs($excel_path)
    $excel.Quit()
}

function Export-ExtendedEventData{
    param(
        [parameter(Mandatory=$true)]$output_file,
        [parameter(Mandatory=$true)][object]$data_table
    )

    $data_table | Export-Csv -Path $output_file -NoTypeInformation

    Convert-ExportToExcelWorkbook -output_file $output_file

    #Clean up
    Remove-Item -Path $output_file
}

function Execute-Query{
    param(
        [Parameter(Mandatory=$true)][object][ValidateNotNullOrEmpty()]$config,
        [Parameter(Mandatory=$true)][string][ValidateNotNullOrEmpty()]$query,
        [Parameter(Mandatory=$true)][validateset('DataRows', 'DataSet', 'DataTables')]$OutputAs
    )

    return Invoke-Sqlcmd -ServerInstance $config.ServerName -Username $config.Username -Password $config.Password -Database $config.DatabaseName -Query $query -OutputAs $OutputAs -OutputSqlErrors $true -IncludeSqlUserErrors

}

function Execute-QueryFile{
    param(
        [Parameter(Mandatory=$true)][object][ValidateNotNullOrEmpty()]$config,
        [Parameter(Mandatory=$true)][string][ValidateNotNullOrEmpty()]$queryFile,
        [Parameter(Mandatory=$true)][validateset('DataRows', 'DataSet', 'DataTables')]$OutputAs
    )

    return Invoke-Sqlcmd -ServerInstance $config.ServerName -Username $config.Username -Password $config.Password -Database $config.DatabaseName -InputFile $queryFile -OutputAs $OutputAs -OutputSqlErrors $true -IncludeSqlUserErrors

}

function Initialize() {
    $Error.Clear()
    Set-Variable -Name "gScriptName"                -Value (Get-Item $PSCommandPath).BaseName                                                                   -Scope Global
    Set-Variable -Name "gBaseDir"                   -Value (Get-Item $PSCommandPath).Directory.FullName                                                         -Scope Global
    Set-Variable -Name "gStartDatetime"             -Value (Get-Date -Format yyyy_MM_dd_HH_mm_ss_fff)                                                           -Scope Global
    Set-Variable -Name "gScriptFullPath"            -Value (Get-Item $PSCommandPath).FullName                                                                   -Scope Global
    Set-Variable -Name "gScriptConfigPath"          -Value "$(Join-Path -Path (Get-Item $gScriptFullPath).Directory.FullName -ChildPath $gScriptName).config"   -Scope Global
    Set-Variable -Name "gLogFilePath"               -Value $PSScriptRoot                                                                                        -Scope Global
    Set-Variable -Name "gLogFullPath"               -Value (Join-Path -Path $gLogFilePath -ChildPath "$($gScriptName).$($gStartDatetime).log")                  -Scope Global
    Set-Variable -Name "gTraceDefinitionsDir"       -Value (Resolve-Path -Path (Join-Path -Path $gScriptConfigPath -ChildPath "../../TraceDefinitions"))        -Scope Global

    # Set up the logger as quickly as possible
    Write-LogPreamble -logFullPath $gLogFullPath
    Add-Content -Value (Get-TitleHeader -repeatedCharacter "#" -totalLength (Get-TitleHeaderLength) -titleValue " Script Results: Start ") -Path $gLogFullPath

    Set-Variable -Name "gStepTracker"               -Value $null                                                                                                -Scope Global
    Set-Variable -Name "gErrMsg"                    -Value $null                                                                                                -Scope Global
    Set-Variable -Name "gScriptStackTrace"          -Value $null                                                                                                -Scope Global
    Set-Variable -Name "gStopWatch"                 -Value ([System.Diagnostics.Stopwatch]::StartNew())                                                         -Scope Global
    Set-Variable -Name "gSelectedInstance"          -Value $null                                                                                                -Scope Global
    Set-Variable -Name "gStepTracker"               -Value (New-Tracker -StepDescriptions $stepDescriptions)                                                    -Scope Global
    Set-Variable -Name "gSilentMode"                -Value $null                                                                                                -Scope Global
    
    # Warnings
    $kWarnBeforeStart = @"
"@

    Set-Variable -Name "gkWarnBBeforeStart"         -Value $kWarnBeforeStart                                                                        -Scope Global

    Write-TraceWithTimestamp -logFullPath $gLogFullPath -message "Initialize() complete" -LogMessageType Info
    
}


try {

    # Import Modules
    Import-Module (Join-Path -Path "$PSScriptRoot" -ChildPath "../../../../../Common" | Join-Path -ChildPath "Logger.ps1") -ErrorAction Stop -Force

    # Init
    Initialize 
    $config = Get-Config -file_path $gScriptConfigPath

    $gStepTracker.SetStep([Step]::Step1, [Status]::InProgress)
        
    # $cnn = Get-SqlConnection -config $config 
    # $cred = Get-SqlCredential -config $config 
    # $results = Invoke-DbaQuery -SqlInstance $config.ServerName -Database $config.DatabaseName -Query "Select 123" -CommandType Text -SqlCredential $cred -ErrorAction Stop -MessagesToOutput 
    $results = Execute-Query -config $config -query "Select 123" -OutputAs DataRows
    

    # Install extended events if asked to do so
    if ($install_extended_events){
        Install-ExtendedEventTraces -config $config -trace_definitions_path $gTraceDefinitionsDir 
    }

    Export-ExtendedEventData -output_file (Join-Path -Path $gBaseDir -ChildPath "SomeFile.csv") -data_table (Execute-Query -config $config -query "SELECT * FROM ExampleTrace1" -OutputAs DataTables)

    # Get data from extended events into 3 tables
    # FastDefault
    # FastOne
    # FastNone

    # Update each table to define new columns needed for later joins

    # Run select, with joins and export to Excel worksheets
    

}
catch {
    $gErrMsg = $PSItem.Exception.Message 
    $gScriptStackTrace = $_.ScriptStackTrace
    Write-Error $_.ErrorDetails
}
finally {
    $gStopWatch.Stop()
    $gEndDatetime = Get-Date -Format yyyy_MM_dd_HH_mm_ss_fff
    Add-Content -Path $gLogFullPath -Value "$(Get-CRLF)$(Get-CRLF)$(Build-LogSuffix)" -ErrorAction Stop    

    Write-Host "Procedure complete: $gLogFullPath" -ForegroundColor DarkYellow

    # Set operating system ERRORLEVEL so that batch scripting knows when there is a failure. Non-zero is an error. 
    exit (![string]::IsNullOrWhiteSpace($gErrMsg)) ? 1 : 0
}