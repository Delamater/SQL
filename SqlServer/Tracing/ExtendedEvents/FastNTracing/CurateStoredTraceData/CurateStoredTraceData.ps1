#requires -Modules SqlServer

param(
    [switch]$install_extended_events
)

enum Step{
    InitializeScript
    EditTablesWithNewData
    CreateViews
    CreateIndexes
}

# Define the steps descriptions
$stepDescriptions = [ordered]@{
    InitializeScript                    = "Initialize Script"
    EditTablesWithNewData               = "Edits tables to create new data needed for analysis"
    CreateViews                         = "Creates necessary views"
    CreateIndexes                       = "Creating indexes"
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
    Set-Variable -Name "gStepTracker"               -Value (New-Tracker -StepDescriptions $stepDescriptions)                                                    -Scope Global
    $gStepTracker.SetStep([Step]::InitializeScript, [Status]::InProgress)
    
    Set-Variable -Name "gErrMsg"                    -Value $null                                                                                                -Scope Global
    Set-Variable -Name "gScriptStackTrace"          -Value $null                                                                                                -Scope Global
    Set-Variable -Name "gStopWatch"                 -Value ([System.Diagnostics.Stopwatch]::StartNew())                                                         -Scope Global
    Set-Variable -Name "gSelectedInstance"          -Value $null                                                                                                -Scope Global
    
    Set-Variable -Name "gSilentMode"                -Value $null                                                                                                -Scope Global
    
    # Warnings
    $kWarnBeforeStart = @"
"@

    Set-Variable -Name "gkWarnBBeforeStart"         -Value $kWarnBeforeStart                                                                                    -Scope Global

    Write-TraceWithTimestamp -logFullPath $gLogFullPath -message "Initialize() complete" -LogMessageType Info
    $gStepTracker.SetStep([Step]::InitializeScript, [Status]::Completed)
    
}

function Add-ColumnsToTable{
    param(
        [Parameter(Mandatory=$true)][string]$table_or_view
    )

    $tsql = @"
IF COL_LENGTH('$table_or_view', 'SelectPosition') IS NOT NULL ALTER TABLE $table_or_view DROP COLUMN SelectPosition;
IF COL_LENGTH('$table_or_view', 'WherePosition') IS NOT NULL ALTER TABLE $table_or_view DROP COLUMN WherePosition;
IF COL_LENGTH('$table_or_view', 'OrderByPosition') IS NOT NULL ALTER TABLE $table_or_view DROP COLUMN OrderByPosition;
IF COL_LENGTH('$table_or_view', 'SelectList') IS NOT NULL ALTER TABLE $table_or_view DROP COLUMN SelectList;
IF COL_LENGTH('$table_or_view', 'WhereClause') IS NOT NULL ALTER TABLE $table_or_view DROP COLUMN WhereClause;
IF COL_LENGTH('$table_or_view', 'OrderByClause') IS NOT NULL ALTER TABLE $table_or_view DROP COLUMN OrderByClause;
IF COL_LENGTH('$table_or_view', 'FastPosition') IS NOT NULL ALTER TABLE $table_or_view DROP COLUMN FastPosition;
IF COL_LENGTH('$table_or_view', 'FastValue') IS NOT NULL ALTER TABLE $table_or_view DROP COLUMN FastValue;
IF COL_LENGTH('$table_or_view', 'OrderByClauseSansFast1') IS NOT NULL ALTER TABLE $table_or_view DROP COLUMN OrderByClauseSansFast1;
IF COL_LENGTH('$table_or_view', 'kUserName') IS NOT NULL ALTER TABLE $table_or_view DROP COLUMN kUserName;
IF COL_LENGTH('$table_or_view', 'kName') IS NOT NULL ALTER TABLE $table_or_view DROP COLUMN kName;

GO

-- Add columns we need for analysis
ALTER TABLE $table_or_view ADD SelectPosition INT
ALTER TABLE $table_or_view ADD WherePosition INT
ALTER TABLE $table_or_view ADD OrderByPosition INT
ALTER TABLE $table_or_view ADD FastPosition INT 
ALTER TABLE $table_or_view ADD FastValue NVARCHAR(MAX)    
ALTER TABLE $table_or_view ADD SelectList NVARCHAR(4000)
ALTER TABLE $table_or_view ADD WhereClause NVARCHAR(4000)
ALTER TABLE $table_or_view ADD OrderByClause NVARCHAR(4000)    
ALTER TABLE $table_or_view ADD OrderByClauseSansFast1 NVARCHAR(4000)
ALTER TABLE $table_or_view ADD kUserName NVARCHAR(50)
ALTER TABLE $table_or_view ADD kName NVARCHAR(50)

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
UPDATE $table_or_view
SET SelectPosition = CHARINDEX('select', lower([statement])),
    WherePosition = CHARINDEX('where', lower([statement])),
    OrderByPosition = CHARINDEX('order by', lower([statement]))
FROM $table_or_view

-- SET SelectList
UPDATE $table_or_view
SET SelectList = SUBSTRING(statement, SelectPosition, WherePosition)
FROM $table_or_view
WHERE SelectPosition > 0 AND WherePosition > 0 

-- SET SelectList without WhereClause
UPDATE $table_or_view
SET SelectList = SUBSTRING(statement, SelectPosition, LEN(statement))
FROM $table_or_view
WHERE SelectPosition > 0 AND WherePosition = 0 AND SelectList IS NULL 

-- SET where clause
UPDATE $table_or_view
SET 
    WhereClause = SUBSTRING(statement, WherePosition, OrderByPosition)
FROM $table_or_view
WHERE WherePosition > 0 AND OrderByPosition > 0

-- SET WhereClause without OrderBy
UPDATE $table_or_view
SET 
    WhereClause = SUBSTRING(statement, WherePosition, LEN(statement))
FROM $table_or_view
WHERE WherePosition > 0 AND OrderByPosition = 0 AND WhereClause IS NULL

-- Update order by clause 
UPDATE $table_or_view
SET 
    OrderByClause = SUBSTRING(statement, OrderByPosition, LEN(statement))
FROM $table_or_view
WHERE OrderByPosition > 0	

-- Set FastPosition and FastValue
UPDATE $table_or_view
SET FastPosition = 
	CASE
		WHEN CHARINDEX('Option (FAST ', OrderByClause) > 0 THEN
			CHARINDEX('Option (FAST ', OrderByClause) 
		ELSE
			NULL
	END,
    FastValue = 
        CASE 
            WHEN CHARINDEX('Option (FAST ', OrderByClause) > 0 
                THEN CAST(SUBSTRING(OrderByClause, CHARINDEX('Option (FAST ', OrderByClause) + LEN('Option (FAST '), CHARINDEX(')', OrderByClause, CHARINDEX('Option (FAST ', OrderByClause) + LEN('Option (FAST ')) - (CHARINDEX('Option (FAST ', OrderByClause) + LEN('Option (FAST '))) AS INT)
            ELSE NULL
        END,
    OrderByClauseSansFast1 = 
        CASE
            WHEN CHARINDEX('Option (FAST ', OrderByClause) > 0
                THEN SUBSTRING(OrderByClause,0,FastPosition)
			WHEN (FastPosition = 0 OR FastPosition IS NULL) THEN OrderByClause
            ELSE NULL
        END 

FROM $table_or_view
WHERE SelectPosition > 0

UPDATE $table_or_view
SET OrderByClauseSansFast1 = SUBSTRING(OrderByClause, 0, FastPosition) 
FROM $table_or_view
WHERE FastPosition > 0

IF EXISTS(
    SELECT 1
        --statement, SelectPosition, WherePosition, OrderByPosition, name, SelectList, WhereClause, OrderByClause
    FROM $table_or_view
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

function New-StatsViews{
    param(
        [Parameter(Mandatory=$true)][string]$table_or_view
    )
    # Add a "v" in front of the table name for views
    $view_name = $table_or_view -replace '^(.*?)\.', '$1.v'
    $view_name += "_STATS"

    $tsql = @"
DROP VIEW IF EXISTS $($view_name)

GO

CREATE VIEW $($view_name) AS 
SELECT 
    statement, 
    COUNT(*) AS ExecutionCount, 
    --AVG(duration) AS AverageDuration_Microseconds,
    --STDEV(duration) AS StdDevDuration_Microseconds,
    --MIN(duration) AS MinDuration_Microseconds,
    --MAX(duration) AS MaxDuration_Microseconds,
    AVG(duration)/1000000.0 AS AVG_duration_Seconds,
    STDEV(duration)/1000000.0 AS STDEV_duration_Seconds,
    MIN(duration)/1000000.0 AS MIN_duration_Seconds,
    MAX(duration)/1000000.0 AS MAX_duration_Seconds,
    AVG(cpu_time) AS AVG_cpu_time,
    MIN(cpu_time) AS MIN_cpu_time,
    MAX(cpu_time) AS MAX_cpu_time,
    AVG(physical_reads) AS AVG_physical_reads,
    MIN(physical_reads) AS MIN_physical_reads,
    MAX(physical_reads) AS MAX_physical_reads,
    STDEV(physical_reads) AS STDEV_physical_reads,
    AVG(logical_reads) AS AVG_logical_read,
    MIN(logical_reads) AS MIN_logical_read,
    MAX(logical_reads) AS MAX_logical_read,
    STDEV(logical_reads) AS STDEV_logical_read,
    AVG(writes) AS AVG_writes,
    MIN(writes) AS MIN_writes,
    MAX(writes) AS MAX_writes,
    STDEV(writes) AS STDEV_writes,
    AVG(row_count) Avg_row_count
FROM $($table_or_view)
WHERE 
    (SelectPosition > 0)    
    AND name = 'sp_statement_completed'
GROUP BY statement
"@    

    return $tsql
}
function New-BaseViews{
    param(
        [Parameter(Mandatory=$true)][string]$table_or_view
    )
    
    # Add a "v" in front of the table name for views
    $view_name = $table_or_view -replace '^(.*?)\.', '$1.v'

    $tsql = @"
DROP VIEW IF EXISTS $($view_name)
GO


CREATE VIEW $($view_name) AS
SELECT 
    name, timestamp, [error_number], username, database_name, 
    options_text, client_app_name,object_name,cpu_time, duration, physical_reads, 
    logical_reads, writes, spills, row_count, result, 
    statement, SelectPosition, WherePosition, OrderByPosition, 
    FastPosition, FastValue, SelectList, WhereClause, OrderByClause, OrderByClauseSansFast1        
FROM            $($table_or_view)
WHERE        
    (SelectPosition > 0)    
    AND name = 'sp_statement_completed'
"@

    return $tsql
}

function Edit-TablesWithNewData{
    param(
        [Parameter(Mandatory=$true)]$config
    )
    
    $config.DataTablesToExport | ForEach-Object {

        $full_sql = @"
$(Add-ColumnsToTable -table_or_view $_)
GO
$(Update-AddedColumns -table_or_view $_)
GO
"@

        # we throw away the results, an error would be trapped if there was one
        Write-TraceWithTimestamp -logFullPath $gLogFullPath -message $full_sql -logMessageType Info 
        Execute-Query -config $config -query $full_sql -OutputAs DataTables -ErrorAction Stop
    }

    $gStepTracker.SetStep([Step]::EditTablesWithNewData, [Status]::InProgress)

    $gStepTracker.SetStep([Step]::EditTablesWithNewData, [Status]::Completed)
}


function New-DetailedViews{
    param(
        [Parameter(Mandatory=$true)]$config
    )

    # DEFAULT vs FAST
    $tsql = @"
    CREATE VIEW dbo.vDEFAULT_vs_FALSE AS
    select d.name, d.timestamp, d.statement, d.logical_reads logical_reads_d, f.logical_reads logical_reads_f, d.physical_reads physical_reads_d , f.physical_reads physical_reads_f, d.cpu_time cpu_time_d, f.cpu_time cpu_time_f, d.duration duration_d, f.duration duration_f
    from dbo.vFAST_DEFAULT d
        inner join dbo.vFAST_FALSE f
            ON d.SelectList = f.SelectList
            AND d.WhereClause = f.WhereClause
            AND COALESCE(d.OrderByClause,'ZZZ') = COALESCE(f.OrderByClauseSansFast1,'ZZZ')
    WHERE 
        d.SelectPosition > 0 
        AND d.statement NOT LIKE '%UPDATE%' AND d.statement NOT LIKE '%INSERT INTO%'
"@
    Write-TraceWithTimestamp -logFullPath $gLogFullPath -message $tsql -logMessageType Info 
    Execute-Query -config $config -query $tsql -OutputAs DataRows -ErrorAction Stop

    $tsql = @"
CREATE VIEW dbo.vFALSE_vs_NONE AS
select f.name, f.timestamp, f.statement, f.logical_reads logical_reads_f, n.logical_reads logical_reads_n, f.physical_reads physical_reads_f , n.physical_reads physical_reads_n, f.cpu_time cpu_time_f, n.cpu_time cpu_time_n, f.duration duration_f, n.duration duration_n
from dbo.vFAST_FALSE f
    inner join dbo.vFAST_NONE n
        ON f.SelectList = n.SelectList
        AND f.WhereClause = n.WhereClause
        AND COALESCE(f.OrderByClause,'ZZZ') = COALESCE(n.OrderByClauseSansFast1,'ZZZ')
WHERE 
    f.SelectPosition > 0 
    AND f.statement NOT LIKE '%UPDATE%' AND f.statement NOT LIKE '%INSERT INTO%'
"@

    Write-TraceWithTimestamp -logFullPath $gLogFullPath -message $tsql -logMessageType Info 
    Execute-Query -config $config -query $tsql -OutputAs DataRows -ErrorAction Stop
}

function New-Indexes{
    param(
        [Parameter(Mandatory=$true)]$config
    )

    $gStepTracker.SetStep([Step]::CreateIndexes, [Status]::InProgress)
    $config.DataTablesToExport | ForEach-Object {
        $tsql = @"
DROP INDEX IF EXISTS clsKey ON $($_)
DROP INDEX IF EXISTS idxCovering ON $($_)
GO
CREATE CLUSTERED INDEX clsKey ON $($_)(kUserName ASC, timestamp)
CREATE NONCLUSTERED INDEX idxCovering ON $($_)(kUserName, timestamp, kName) INCLUDE(name, SelectList, WhereClause, OrderByClause, OrderByClauseSansFast1, logical_reads, physical_reads, duration, cpu_time)
"@
    
        Write-TraceWithTimestamp -logFullPath $gLogFullPath -message $tsql -logMessageType Info 
        Execute-Query -config $config -query $tsql -OutputAs DataRows -ErrorAction Stop
    }

    $gStepTracker.SetStep([Step]::CreateIndexes, [Status]::InProgress)
}

function New-Views{
    param(
        [Parameter(Mandatory=$true)]$config
    )

    $gStepTracker.SetStep([Step]::CreateViews, [Status]::InProgress)
    $config.DataTablesToExport | ForEach-Object {

        $full_sql = @"
$(New-BaseViews -table_or_view $_)

GO

$(New-StatsViews -table_or_view $_)
"@

        # we throw away the results, an error would be trapped if there was one
        Write-TraceWithTimestamp -logFullPath $gLogFullPath -message $full_sql -logMessageType Info 
        Execute-Query -config $config -query $full_sql -OutputAs DataTables -ErrorAction Stop
    }

    $gStepTracker.SetStep([Step]::CreateViews, [Status]::Completed)    
}

try {

    # Import Modules
    Import-Module (Join-Path -Path "$PSScriptRoot" -ChildPath "../../../../../Common" | Join-Path -ChildPath "Logger.ps1") -ErrorAction Stop -Force

    # Init
    Initialize 
    $config = Get-Config -file_path $gScriptConfigPath

    # Edit-TablesWithNewData -config $config
    # New-Views -config $config        
    New-Indexes -config $config 
    New-DetailedViews -config $config 
return
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

    if (![string]::IsNullOrWhiteSpace($gErrMsg)){
        Write-Host "Procedure ended in error, please check the log" -ForegroundColor DarkRed
        Write-Host "Procedure complete: $gLogFullPath" -ForegroundColor DarkRed
        exit 1
    }else{
        Write-Host "Procedure complete: $gLogFullPath" -ForegroundColor DarkYellow
        exit 0
    }
    
}