-- ==========================================
-- Search X3 Messages
-- ==========================================
SELECT 
	'mess(' + CONVERT(VARCHAR(10), LANNUM_0) + ',' + CONVERT(VARCHAR(10), LANCHP_0) + ',1' + ')' PlugMeIntoTheX3Calculator, 
	LANMES_0, LAN_0 
FROM <Folder Name,VARCHAR(255),SUPV5>.APLSTD 
WHERE LOWER(LANMES_0) like N'%<Search Value typed in lower case,VARCHAR(255),refused access%>%'
AND LAN_0 = N'<Language,VARCHAR(25),ENG>'