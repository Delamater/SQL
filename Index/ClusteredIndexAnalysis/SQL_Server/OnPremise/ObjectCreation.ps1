$Instance = "127.0.0.1"
$User = "SA"
$Password = "yourStrong(!)Password"
$dbName = "clusteredIndexAnalysis"
$queryTimeout = 10

function InitDatabase(){
    $curPath = (Join-Path -Path ($PSScriptRoot) "Resources")
    
    ExecuteFileQuery -filePath $(Join-Path -Path $curPath -ChildPath "CreateDatabase.sql" -Resolve) 
    ExecuteFileQuery -filePath $(Join-Path -Path $curPath -ChildPath "CreateObjects.sql" -Resolve) -dbName $dbName
    ExecuteFileQuery -filePath $(Join-Path -Path $curPath -ChildPath "InsertData.sql" -Resolve) -dbName $dbName
    ExecuteFileQuery -filePath $(Join-Path -Path $curPath -ChildPath "..\..\..\..\..\Locking\beta_lockinfo.sql" -Resolve) -dbName $dbName
}

function Cleanup(){
    # ExecuteFileQuery("../../Resources/DestroyDatabase.sql")
    [System.Data.SqlClient.SqlConnection]::ClearAllPools()
}

function ExecuteFileQuery($filePath, $dbName){
    if ($dbName){
        $retVal = Invoke-Sqlcmd -InputFile $filePath -ServerInstance $Instance -Username $User -Password $Password -Database $dbName -ErrorAction Stop -QueryTimeout $queryTimeout
    } else{
        $retVal = Invoke-Sqlcmd -InputFile $filePath -ServerInstance $Instance -Username $User -Password $Password -ErrorAction Stop -QueryTimeout $queryTimeout
    }

    return $retVal
}

function ExecuteAdHocQuery($query, $dbName){
    
    if ($dbName){
        $retVal = Invoke-Sqlcmd -Query $query -ServerInstance $Instance -Username $User -Password $Password -Database $dbName -ErrorAction Stop -QueryTimeout $queryTimeout
    } else{
        $retVal = Invoke-Sqlcmd -Query $query -ServerInstance $Instance -Username $User -Password $Password -ErrorAction Stop -QueryTimeout $queryTimeout
    }
    
    return $retVal
}

try {
    ExecuteAdHocQuery("Select 'Testing Connection'")    
    # Init database
    InitDatabase



    # Cleanup
    Cleanup
    Write-Host "Procedure complete"

}
catch {
    Cleanup
    Write-Host $_.Exception.Message
    Write-Host $_.ScriptStackTrace
}

