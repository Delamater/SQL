SELECT value_in_use,
	CASE value_in_use
		WHEN 0 THEN 'Priority boost is turned off. This is the recommended state.'
		WHEN 1 THEN 'Priority boost is turned on. This is not recommended.'
		ELSE 'The state of priority boost is unknown. No recommendation can be made'
	END
FROM sys.configurations
WHERE
	name = 'priority boost'
	AND configuration_id = 1517
