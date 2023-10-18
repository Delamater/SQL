#requires -Modules SqlServer

param(
    [switch]$install_extended_events
)

enum Step{
    InitializeScript
    CreateViewsWithNewData
    Step1
    Step2
    Step3
}

# Define the steps descriptions
$stepDescriptions = [ordered]@{
    InitializeScript                    = "Initialize Script"
    CreateViewsWithNewData              = "Add columns to base table and create view"
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
        [parameter(Mandatory=$true)][string]$table_or_view
    )

    return Execute-Query -config $config -query "SELECT * FROM $table_or_view" -OutputAs DataTables 
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

function Export-DataTableToCsv{
    param(
        [parameter(Mandatory=$true)]$output_file,
        [parameter(Mandatory=$true)][object]$data_table
    )

    $data_table | Export-Csv -Path $output_file -NoTypeInformation 

    # Convert-ExportToExcelWorkbook -output_file $output_file

    #Clean up
    # Remove-Item -Path $output_file
}

function Execute-Query{
    param(
        [Parameter(Mandatory=$true)][object][ValidateNotNullOrEmpty()]$config,
        [Parameter(Mandatory=$true)][string][ValidateNotNullOrEmpty()]$query,
        [Parameter(Mandatory=$true)][validateset('DataRows', 'DataSet', 'DataTables')]$OutputAs
    )

    return Invoke-Sqlcmd -ServerInstance $config.ServerName -Username $config.Username -Password $config.Password -Database $config.DatabaseName -Query $query -OutputAs $OutputAs -OutputSqlErrors $true -IncludeSqlUserErrors -ErrorAction Stop

}

function Execute-QueryFile{
    param(
        [Parameter(Mandatory=$true)][object][ValidateNotNullOrEmpty()]$config,
        [Parameter(Mandatory=$true)][string][ValidateNotNullOrEmpty()]$queryFile,
        [Parameter(Mandatory=$true)][validateset('DataRows', 'DataSet', 'DataTables')]$OutputAs
    )

    return Invoke-Sqlcmd -ServerInstance $config.ServerName -Username $config.Username -Password $config.Password -Database $config.DatabaseName -InputFile $queryFile -OutputAs $OutputAs -OutputSqlErrors $true -IncludeSqlUserErrors -ErrorAction Stop

}

function Initialize() {
    $Error.Clear()
    $gStepTracker.SetStep([Step]::Step1, [Status]::InProgress)
    Set-Variable -Name "gScriptName"                -Value (Get-Item $PSCommandPath).BaseName                                                                   -Scope Global
    Set-Variable -Name "gBaseDir"                   -Value (Get-Item $PSCommandPath).Directory.FullName                                                         -Scope Global
    Set-Variable -Name "gStartDatetime"             -Value (Get-Date -Format yyyy_MM_dd_HH_mm_ss_fff)                                                           -Scope Global
    Set-Variable -Name "gScriptFullPath"            -Value (Get-Item $PSCommandPath).FullName                                                                   -Scope Global
    Set-Variable -Name "gScriptConfigPath"          -Value "$(Join-Path -Path (Get-Item $gScriptFullPath).Directory.FullName -ChildPath $gScriptName).config"   -Scope Global
    Set-Variable -Name "gLogFilePath"               -Value $PSScriptRoot                                                                                        -Scope Global
    Set-Variable -Name "gLogFullPath"               -Value (Join-Path -Path $gLogFilePath -ChildPath "$($gScriptName).$($gStartDatetime).log")                  -Scope Global
    Set-Variable -Name "gAssetsFolder"              -Value (Resolve-Path -Path (Join-Path -Path $gScriptConfigPath -ChildPath "../../Assets"))                  -Scope Global

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

    Set-Variable -Name "gkWarnBBeforeStart"         -Value $kWarnBeforeStart                                                                                    -Scope Global

    Write-TraceWithTimestamp -logFullPath $gLogFullPath -message "Initialize() complete" -LogMessageType Info
    $gStepTracker.SetStep([Step]::Step1, [Status]::Completed)
    
}

function Add-ColumnsToTable{
    param(
        [Parameter(Mandatory=$true)][string]$table_or_view
    )

    $tsql = @"
IF COL_LENGTH('dbo.$table_or_view', 'SelectPosition') IS NOT NULL ALTER TABLE dbo.$table_or_view DROP COLUMN SelectPosition;
IF COL_LENGTH('dbo.$table_or_view', 'WherePosition') IS NOT NULL ALTER TABLE dbo.$table_or_view DROP COLUMN WherePosition;
IF COL_LENGTH('dbo.$table_or_view', 'OrderByPosition') IS NOT NULL ALTER TABLE dbo.$table_or_view DROP COLUMN OrderByPosition;
IF COL_LENGTH('dbo.$table_or_view', 'SelectList') IS NOT NULL ALTER TABLE dbo.$table_or_view DROP COLUMN SelectList;
IF COL_LENGTH('dbo.$table_or_view', 'WhereClause') IS NOT NULL ALTER TABLE dbo.$table_or_view DROP COLUMN WhereClause;
IF COL_LENGTH('dbo.$table_or_view', 'OrderByClause') IS NOT NULL ALTER TABLE dbo.$table_or_view DROP COLUMN OrderByClause;
IF COL_LENGTH('dbo.$table_or_view', 'FastPosition') IS NOT NULL ALTER TABLE dbo.$table_or_view DROP COLUMN FastPosition;
IF COL_LENGTH('dbo.$table_or_view', 'FastValue') IS NOT NULL ALTER TABLE dbo.$table_or_view DROP COLUMN FastValue;



-- Add columns we need for analysis
ALTER TABLE dbo.$table_or_view ADD SelectPosition INT
ALTER TABLE dbo.$table_or_view ADD WherePosition INT
ALTER TABLE dbo.$table_or_view ADD OrderByPosition INT
ALTER TABLE dbo.$table_or_view ADD FastPosition NVARCHAR(MAX)    
ALTER TABLE dbo.$table_or_view ADD FastValue NVARCHAR(MAX)    
ALTER TABLE dbo.$table_or_view ADD SelectList NVARCHAR(MAX)
ALTER TABLE dbo.$table_or_view ADD WhereClause NVARCHAR(MAX)
ALTER TABLE dbo.$table_or_view ADD OrderByClause NVARCHAR(MAX)    

"@

    return $tsql
}

function Update-AddedColumns{
    param(
        [Parameter(Mandatory=$true)][string]$table_or_view
    )

    $tsql = @"
BEGIN TRY
BEGIN TRAN

-- Get some meta data about the position of key statement constructs
UPDATE dbo.$table_or_view
SET SelectPosition = CHARINDEX('select', lower([statement])),
    WherePosition = CHARINDEX('where', lower([statement])),
    OrderByPosition = CHARINDEX('order by', lower([statement]))
FROM dbo.$table_or_view

-- SET SelectList
UPDATE dbo.$table_or_view
SET SelectList = SUBSTRING(statement, SelectPosition, WherePosition)
FROM dbo.$table_or_view
WHERE SelectPosition > 0 AND WherePosition > 0 

-- SET SelectList without WhereClause
UPDATE dbo.$table_or_view
SET SelectList = SUBSTRING(statement, SelectPosition, LEN(statement))
FROM dbo.$table_or_view
WHERE SelectPosition > 0 AND WherePosition = 0 AND SelectList IS NULL 

-- SET where clause
UPDATE dbo.$table_or_view
SET 
    WhereClause = SUBSTRING(statement, WherePosition, OrderByPosition)
FROM dbo.$table_or_view
WHERE WherePosition > 0 AND OrderByPosition > 0

-- SET WhereClause without OrderBy
UPDATE dbo.$table_or_view
SET 
    WhereClause = SUBSTRING(statement, WherePosition, LEN(statement))
FROM dbo.$table_or_view
WHERE WherePosition > 0 AND OrderByPosition = 0 AND WhereClause IS NULL

-- Update order by clause 
UPDATE dbo.$table_or_view
SET 
    OrderByClause = SUBSTRING(statement, OrderByPosition, LEN(statement))
FROM dbo.$table_or_view
WHERE OrderByPosition > 0	

-- Set FastPosition and FastValue
UPDATE dbo.$table_or_view
SET FastPosition = 
	CASE
		WHEN CHARINDEX('Option (FAST', statement) > 0 THEN
			CHARINDEX('Option (FAST', statement) + LEN('Option (FAST') 
		ELSE
			NULL
	END,
	FastValue = 
	CASE 
		WHEN CHARINDEX('Option (FAST', statement) > 0 THEN
            CAST(SUBSTRING(statement, CHARINDEX('Option (FAST', statement) + LEN('Option (FAST'), 
            CHARINDEX(')', statement, CHARINDEX('Option (FAST', statement)) - (CHARINDEX('Option (FAST', statement) + LEN('Option (FAST'))) AS INT)			
		ELSE
			NULL
	END
FROM dbo.$table_or_view
WHERE SelectPosition > 0

IF EXISTS(
    SELECT 1
        --statement, SelectPosition, WherePosition, OrderByPosition, name, SelectList, WhereClause, OrderByClause
    FROM dbo.$table_or_view
    WHERE 
        (SelectPosition > 0 AND SelectList IS NULL) OR
        (WherePosition > 0 AND WhereClause IS NULL) OR
        (OrderByPosition > 0 AND OrderByClause IS NULL)
)
BEGIN
    THROW 51000, 'Not all of the statements were parsed properly during the statement parsing phase', 1
END

COMMIT TRAN
END TRY
BEGIN CATCH
    SELECT ERROR_LINE(), ERROR_NUMBER(), ERROR_MESSAGE(), ERROR_PROCEDURE(), ERROR_SEVERITY(), ERROR_STATE()
    ROLLBACK
END CATCH
"@
    return $tsql
}

function New-View{
    param(
        [Parameter(Mandatory=$true)][string]$table_or_view
    )

    $tsql = @"
DROP VIEW IF EXISTS dbo.v$table_or_view
GO

-- WITH OPTION FAST
CREATE VIEW dbo.v$table_or_view_f AS
SELECT *       
FROM            $table_or_view
WHERE        
    (SelectPosition > 0)
    AND f.FastPosition IS NOT NULL

-- SANS OPTION FAST
CREATE VIEW dbo.v$table_or_view_sf AS
SELECT *       
FROM            $table_or_view
WHERE        
    (SelectPosition > 0)
    AND f.FastPosition IS NULL
    
"@

    return $tsql
}


function New-ViewsWithNewData{
    param(
        [Parameter(Mandatory=$true)]$config
    )

    $gStepTracker.SetStep([Step]::CreateViewsWithNewData, [Status]::InProgress)
    $config.DataTablesToExport | ForEach-Object {
        $full_sql = @"
$(Add-ColumnsToTable -table_or_view $_)
$(Update-AddedColumns -table_or_view $_)
$(New-View -table_or_view $_)
"@

        # we throw away the results, an error would be trapped if there was one
        Write-TraceWithTimestamp -logFullPath $gLogFullPath -message $full_sql -logMessageType Info 
        Execute-Query -config $config -query $full_sql -OutputAs DataTables
        
        $gStepTracker.SetStep([Step]::CreateViewsWithNewData, [Status]::Completed)
    }
}

try {

    # Import Modules
    Import-Module (Join-Path -Path "$PSScriptRoot" -ChildPath "../../../../../Common" | Join-Path -ChildPath "Logger.ps1") -ErrorAction Stop -Force

    # Init
    Initialize 
    $config = Get-Config -file_path $gScriptConfigPath

    New-ViewsWithNewData -config $config        

    # Install extended events if asked to do so
    if ($install_extended_events){
        Install-ExtendedEventTraces -config $config -trace_definitions_path $gAssetsFolder 
    }

    $config.DataTablesToExport | ForEach-Object{
        $tv = $_
        Export-DataTableToCsv -output_file (Join-Path -Path $gBaseDir -ChildPath "$($_).csv") -data_table (Get-ExtendedEventData -config $config -table_or_view "dbo.v$($tv)")
    }
    

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
    [System.Data.SqlClient.SqlConnection]::ClearAllPools()
    Add-Content -Path $gLogFullPath -Value "$(Get-CRLF)$(Get-CRLF)$(Build-LogSuffix)" -ErrorAction Stop    

    Write-Host "Procedure complete: $gLogFullPath" -ForegroundColor DarkYellow

    # Set operating system ERRORLEVEL so that batch scripting knows when there is a failure. Non-zero is an error. 
    exit (![string]::IsNullOrWhiteSpace($gErrMsg)) ? 1 : 0
}