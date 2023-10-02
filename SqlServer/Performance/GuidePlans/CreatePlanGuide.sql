CREATE PROCEDURE dbo.usp_create_plan_guide_with_hint
	@plan_handle VARBINARY(64),
	@statement_start_offset INT,
	@name NVARCHAR(128),
	@hints NVARCHAR(MAX)
AS
BEGIN
	DECLARE @model_name NVARCHAR(128)
	DECLARE @query_text NVARCHAR(MAX)
	DECLARE @scope_type_desc NVARCHAR(60)
	DECLARE @scope_object_id INT
	DECLARE @scope_batch NVARCHAR(MAX)
	DECLARE @parameters NVARCHAR(MAX)
	DECLARE @procedure_name NVARCHAR(128)

	SET @model_name = @name + '_model'

	exec sp_create_plan_guide_from_handle @plan_handle = @plan_handle, @statement_start_offset = @statement_start_offset, @name = @model_name

	SELECT 
		@query_text = query_text, @scope_type_desc = scope_type_desc,
		@scope_object_id = scope_object_id,
		@scope_batch = scope_batch, @parameters = parameters
	FROM sys.plan_guides 
	WHERE name = @model_name

	exec sp_control_plan_guide @name = @model_name, @operation = 'DROP'

	IF @scope_object_id IS NOT NULL
	BEGIN
		SELECT @procedure_name = OBJECT_NAME(@scope_object_id)

		exec sp_create_plan_guide @name = @name, @stmt = @query_text, @module_or_batch=@procedure_name, @type=@scope_type_desc, @params = @parameters, @hints = @hints
	END
	ELSE
	BEGIN
		exec sp_create_plan_guide @name = @name, @stmt = @query_text, @module_or_batch=@scope_batch,
		@type=@scope_type_desc, @params = @parameters,
		@hints = @hints
	END
END

