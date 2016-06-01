/*
Overview:
Searches all procedures for particular text

NOTE:
- this is an older script and I have not looked to see if there is now
a better way to do this... but at the time this was a "fool proof" way
of doing it since just querying syscomments could be unreliable if proc
was really big
*/

IF NOT OBJECT_ID('tempdb..#ProcDefinitions') IS NULL 
    DROP TABLE #ProcDefinitions;

SELECT  
    o.name ProcName,
	OBJECT_DEFINITION(o.object_id) ProcText 
INTO #ProcDefinitions 
FROM sys.sql_modules m 
JOIN sys.objects o 
    ON o.object_id = m.object_id 
WHERE 
    o.type = 'P' 
    AND  
    ( 
        o.name like 'ucp[_]r[_]RMB%' 
        OR 
        o.name like 'ucp[_]i[_]RMB%' 
        OR 
        o.name like 'ucp[_]s[_]RMB%' 
    ) 
ORDER BY 
    o.name;

DECLARE @SearchText NVARCHAR(500) = 'valuation';
SELECT DISTINCT 
    #ProcDefinitions.ProcName,
    '...' + SUBSTRING(ProcText, CHARINDEX(@SearchText, ProcText) - 50, LEN(@SearchText) + 150) + '...' 
FROM #ProcDefinitions 
WHERE  
    ProcText LIKE '%' + @SearchText + '%' 
ORDER BY 
    #ProcDefinitions.ProcName;

