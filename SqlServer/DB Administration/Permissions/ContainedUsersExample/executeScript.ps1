# Execute input script under different user accounts for a test
$inputFile = ".\testScript.sql"
$tearDownScript = ".\teardown.sql"
$db = "ContainedDBTest"
$user = "SEED"
$password = "pass1234"
$cnnTimeout = 5
$server = "X3ERPV12VM\SQL2K17FORX3"


Function ExecuteSql($ServerName, $inputFile, $user, $pwd, $dbName, $outputFileName) {
    <#
    .Description Takes an input file, authentication parameters and executes output to a file
    #>

    if ($user.Length -eq 0) {
        if ($dbName.Length -eq 0){
            Invoke-Sqlcmd -InputFile $inputFile -ServerInstance $ServerName -ConnectionTimeout 5 | Export-Csv $outputFileName -Delimiter "," -NoTypeInformation
            #Start-Process -FilePath "sqlcmd" -ArgumentList "S$ServerName -i$inputFile -o$outputFileName"
        }else{
            Invoke-Sqlcmd -InputFile $inputFile -ServerInstance $ServerName -ConnectionTimeout 5 -Database $dbName | Export-Csv $outputFileName -Delimiter "," -NoTypeInformation
            #Start-Process -FilePath "sqlcmd" -ArgumentList "S$ServerName -i$inputFile -U$user -P$pwd -o$outputFileName"
        }
        
    } else{
        if ($dbName -eq 0){
            Invoke-Sqlcmd -InputFile $inputFile -ServerInstance $ServerName -ConnectionTimeout 5 -Username $user -Password $pwd | Export-Csv $outputFileName -Delimiter "," -NoTypeInformation
            #Start-Process -FilePath "sqlcmd" -ArgumentList "S$ServerName -i$inputFile -d$dbName -o$outputFileName"
        }else{
            Invoke-Sqlcmd -InputFile $inputFile -ServerInstance $ServerName -ConnectionTimeout 5 -Database $dbName -Username $user -Password $pwd | Export-Csv $outputFileName -Delimiter "," -NoTypeInformation
            #Start-Process -FilePath "sqlcmd" -ArgumentList "S$ServerName -i$inputFile -U$user -P$pwd -d$dbName -o$outputFileName"
        }
        
    }
    
}


try{
    # Teardown if needed
    # ExecuteSql -ServerName $server -inputFile $inputFile -outputFileName ".\teardown.csv" 
    ExecuteSql -ServerName $server -inputFile ".\setupScript.sql"  -outputFileName  ".\setup.csv"
    ExecuteSql -ServerName $server -inputFile ".\testscript.sql"  -dbName $db  -outputFileName  ".\testScriptTrusted.csv"
    ExecuteSql -ServerName $server -inputFile ".\testscript.sql"  -dbName $db  -outputFileName  ".\testScriptSEED.csv" -user $user -pwd $password
    return
    # ExecuteSql -ServerName $server -inputFile ".\teardown.sql"    -outputFileName  ".\teardown.csv"
    #write-host "Teadrdown complete"
} catch{
    Write-Host "Error: " $Error[0].Exception
}
