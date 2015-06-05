DECLARE  @ObjectIDs AS dbo.ObjectIDs ;

INSERT INTO @ObjectIDs(ObjectId, SchemaName, TableName)
SELECT t.object_id, s.name, t.name
FROM sys.tables t
	INNER JOIN sys.schemas s
		ON t.schema_id = s.schema_id
WHERE 
	s.name = 'PERSON' 
	AND t.name IN
	(
		'PERSON',
		'ITMMASTER'
	)


exec dbo.uspGetDiscreteIndexFrag 
	@ObjectIDs, @FragPercent = 0, 
	@PageCount = 0, 
	@Rebuild = 0, 
	@Reorganize = 0, 
	@RebuildHeap = 0, 
	@MaxDop = 64
