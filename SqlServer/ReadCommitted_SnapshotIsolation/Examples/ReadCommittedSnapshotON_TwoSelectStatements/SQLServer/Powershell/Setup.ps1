$Instance = "127.0.0.1"
$User = "SA"
$Password = "yourStrong(!)Password"
$dbName = "dbTest"
$queryTimeout = 10

function InitDatabase(){
    $curPath = (Join-Path -Path ($PSScriptRoot) "Resources")
    
    ExecuteFileQuery -filePath $(Join-Path -Path $curPath -ChildPath "CreateDatabase.sql") 
    ExecuteFileQuery -filePath $(Join-Path -Path $curPath -ChildPath "CreateObjects.sql") -dbName $dbName
    ExecuteFileQuery -filePath $(Join-Path -Path $curPath -ChildPath "InsertData.sql") -dbName $dbName
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

    Cleanup
    Write-Host "Procedure complete"

}
catch {
    Cleanup
    Write-Host $_.Exception.Message
    Write-Host $_.ScriptStackTrace
}

