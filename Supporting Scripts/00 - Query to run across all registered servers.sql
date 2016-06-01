/*
Overview:
Simplistic query to run across registered servers
*/
SELECT @@SERVERNAME;

SELECT COUNT(*)
FROM msdb.sys.objects;

EXEC sp_Blitz;

/*
Overview:
Demonstrates inserting lots of data.
NOTE: this query could actually be extended to show disk usage too
... but didn't bother for presentation
*/
SET NOCOUNT ON

IF NOT OBJECT_ID('tempdb..#SomeTable') IS NULL
	DROP TABLE #SomeTable;

CREATE TABLE #SomeTable ( 
    c1 INT IDENTITY, 
    c2 CHAR(8000) DEFAULT 'filler' 
);
GO 

INSERT INTO #SomeTable DEFAULT VALUES;
GO 1280 

SELECT COUNT(*) FROM #SomeTable;
