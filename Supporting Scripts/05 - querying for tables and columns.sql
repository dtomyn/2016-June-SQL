/*
Overview:
Simple demonstration of using meta data to query for objects...
INFORMATION_SCHEMA or sys views? 
Recommendation is to use sys views 
(although I am still use to using INFORMATION_SCHEMA)
*/

SELECT 
	c.TABLE_NAME,
	c.COLUMN_NAME,
	t.TABLE_TYPE
FROM INFORMATION_SCHEMA.COLUMNS c
JOIN INFORMATION_SCHEMA.TABLES t
	ON t.TABLE_SCHEMA = c.TABLE_SCHEMA
	AND t.TABLE_NAME = c.TABLE_NAME
	AND t.TABLE_TYPE = 'BASE TABLE'
ORDER BY
	c.TABLE_NAME,
	c.COLUMN_NAME;

SELECT
	t.name AS TABLE_NAME,
	c.name AS COLUMN_NAME,
	t.type_desc
FROM sys.columns c
JOIN sys.tables t
	ON t.object_id = c.object_id 
ORDER BY
	t.name,
	c.name;
