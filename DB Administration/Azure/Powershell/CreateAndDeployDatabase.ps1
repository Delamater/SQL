# Connect-AzAccount
$SubscriptionId = '057e71df-f482-44b7-8d22-21acabc04500'
# Set the resource group name and location for your server
$resourceGroupName = "GB2_X3-261854-Spike"

# Set elastic pool names
$poolName = "gb2elasticpool "
# Set an admin login and password for your database
$adminSqlLogin = "gb2admin"
$password = "LEuEGqnVCXESi43"
# The logical server name has to be unique in the system
$serverName = "gb2elasticpoolserver.database.windows.net"
# The sample database names
$firstDatabaseName = "somedatabase"

try {
    # Set subscription 
    Set-AzContext -SubscriptionId $subscriptionId 

    # Create a blank database with an S0 performance level
    $database = New-AzSqlDatabase -ResourceGroupName $resourceGroupName -ServerName $serverName -DatabaseName $firstDatabaseName -RequestedServiceObjectiveName "S0" -CollationName "LATIN1_GENERAL_BIN2" 

}
catch {
    Write-Error $PSItem.InvocationInfo | Format-List *
    Write-Error $PSItem.ScriptStackTrace
}
