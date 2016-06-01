/*
Overview:
When doing performance tuning, have available the following...

code to clear the caches:
- CHECKPOINT
	- NOTE: the below cleaning of buffers drops *clean* pages from pool...
	so... need to perform a CHECKPOINT first 

- DBCC FreeProcCache | FreeSystemCache | FlushProcInDB(<dbid>)
	- free proc cache... clears everything
	- flush proc in db... just the procedure caches in 
	- for a complete list see the following by Glen Berry:
	http://www.sqlskills.com/blogs/glenn/eight-different-ways-to-clear-the-sql-server-plan-cache/

- DBCC DropCleanBuffers
	- clears out the entire buffer cache

code to set measurements:
- SET STATISTICS TIME ON
- SET STATISTICS IO ON
- SET SHOWPLAN TEXT|XML or **graphic execution plans*

NOTE: cant view plan in production? Ask to be given the following permission
GRANT SHOWPLAN TO [user] 
*/

--first... let's "dirty up" some pages
BEGIN TRAN;
	UPDATE Person.Person
	SET FirstName = 'Darek';
ROLLBACK TRAN;
 
SELECT 
	*,
	[DirtyPageCount] * 8 / 1024 AS [DirtyPageMB]
FROM
	(SELECT
		(CASE WHEN ([database_id] = 32767)
			THEN N'Resource Database'
			ELSE DB_NAME ([database_id]) END) AS [DatabaseName],
		SUM (CASE WHEN ([is_modified] = 1)
			THEN 1 ELSE 0 END) AS [DirtyPageCount],
		SUM (CASE WHEN ([is_modified] = 1)
			THEN 0 ELSE 1 END) AS [CleanPageCount]
	FROM sys.dm_os_buffer_descriptors
	GROUP BY [database_id]) AS [buffers]
ORDER BY [DatabaseName];

--if drop clean buffers now and re-run above there will still be buffers populated
DBCC DROPCLEANBUFFERS;

--so... checkpoint first!
CHECKPOINT;

--then drop clean buffers

-- Example 1 (Sledgehammer)
-- Remove all elements from the plan cache for the entire instance 
DBCC FREEPROCCACHE;

-- Flush the cache and suppress the regular completion message
-- "DBCC execution completed. If DBCC printed error messages, contact your system administrator." 
DBCC FREEPROCCACHE WITH NO_INFOMSGS;

-- Example 2 (Ballpeen hammer)
-- Remove all elements from the plan cache for one database  
DECLARE @DBID INT = DB_ID('AdventureWorks2014');
DBCC FLUSHPROCINDB (@DBID);

-- Example 3 (Scalpel)
-- Remove one plan from the cache
-- Get the plan handle for a cached plan
SELECT cp.plan_handle, st.[text]
FROM sys.dm_exec_cached_plans AS cp 
CROSS APPLY sys.dm_exec_sql_text(plan_handle) AS st
WHERE [text] LIKE N'%/*uspGetBillOfMaterials%';

-- Remove the specific plan from the cache using the plan handle
DBCC FREEPROCCACHE (0x06000C007744241EC08E38D80100000001000000000000000000000000000000000000000000000000000000);

--EXEC uspGetManagerEmployees 11

