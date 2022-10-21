-- RAW Physical Location Data Without Formatting Applied
-- Generally unusable without transforming it from Hex to human readable format 
SELECT TOP 100 %%physloc%% PhysicalLocationData, cal.*
FROM SEED.CPTANALIN cal

-- Get Page Location Format Information In Single Column
SELECT TOP 100 sys.fn_PhysLocFormatter(%%physloc%%) AS PLF, *
FROM SEED.CPTANALIN cal

-- Break out physical location into usable columns
SELECT TOP 100 loc.*, cal.*
FROM SEED.CPTANALIN cal
	CROSS APPLY sys.fn_PhysLocCracker(%%physloc%%) loc
ORDER BY loc.file_id, loc.page_id, loc.slot_id