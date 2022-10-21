Install-Module PostgreSQLCmdlets
$postgresql = Connect-PostgreSQL  -User "unicorn_user" -Password "magical_password" -Database "rainbow_database" -Server "localhost" -Port "5432"

$shipcountry = "USA"
$orders = Select-PostgreSQL -Connection $postgresql -Table "Orders" -Where "ShipCountry = `'$ShipCountry`'"
$orders