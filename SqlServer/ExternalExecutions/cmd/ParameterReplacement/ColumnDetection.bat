sqlcmd -S.\SQL2019 -E -i ColumnDetection.sql -v column_name = 'SocialSecurity' -v LogFileName = Failure.log
sqlcmd -S.\SQL2019 -E -i ColumnDetection.sql -v column_name = 'LastName' -v LogFileName = Success.log
