/*
TODO: find script for "SalesOrderDetailEnlarged" from Johnathan K...

ensure SET NOCOUNT ON
...most people do this in procs... great... but also ensure you do in functions (UDF) too!

compound indexes
- most useful from the leftmost column to the rightmost column, in the order they appeared in the CREATE INDEX

*/
DBCC DROPCLEANBUFFERS
GO

/*
Simple-Talk.com - Tim Ford
From: Performance Tuning with Dynamic Management Views
*/

--dm_exec_query_stats is what we are interested in...
--and the dm_exec_sql_text and dm_exec_query_plan
--used to give the supporting information
--NOTE: the avg_reads and avg_writes are in 8k data pages
SELECT TOP 10
	total_elapsed_time,
	DB_NAME(ST.dbid) AS [database],
	execution_count,
	total_worker_time / execution_count AS [avg_cpu],
	total_elapsed_time / execution_count AS [avg_time],
	total_logical_reads / execution_count AS [avg_reads],
	total_logical_writes / execution_count AS [avg_writes],
	SUBSTRING
	(
		ST.text
		, (QS.statement_start_offset / 2) + 1
		, ((CASE QS.statement_end_offset
				WHEN -1 THEN DATALENGTH(ST.text)
				ELSE QS.statement_end_offset
			END - QS.statement_start_offset) / 2) + 1) AS [request],
	query_plan
FROM sys.dm_exec_query_stats QS
	CROSS APPLY sys.dm_exec_sql_text(QS.sql_handle) AS ST
	CROSS APPLY sys.dm_exec_query_plan(QS.plan_handle) AS QP
WHERE
	DB_NAME(ST.[dbid]) = 'COR'
ORDER BY
	total_elapsed_time DESC;

--index usage stats...how busy the indexes are
--can also derive from this... if index with almost no reads then
--an indication that it is not being used!
SELECT 
	OBJECT_NAME(US.[object_id]) AS table_name,
	(US.user_seeks + US.user_scans + US.user_lookups) AS user_reads,
	US.user_updates AS user_writes,
	I.name AS index_name
FROM sys.dm_db_index_usage_stats US
JOIN sys.indexes I
	ON I.object_id = US.object_id
	AND I.index_id = US.index_id
WHERE
	db_name(database_id) = 'COR'
	--AND index_id = 0 --HEAP
	--AND index_id = 1 --CLUSTERED INDEX
	AND OBJECT_NAME(US.object_id) IS NOT NULL
	--the below would be an indicator that perhaps not being used
	AND (US.user_seeks + US.user_scans + US.user_lookups) < 1000
ORDER BY 
	2 DESC

SELECT
	db_name(ioFS.database_id) AS the_database,
	MF.name AS logical_file_name,
	MF.physical_name,
	ioFS.io_stall_read_ms / ioFS.num_of_reads AS avg_read_stall_ms,
	ioFS.num_of_reads,
	ioFS.num_of_bytes_read,
	ioFS.size_on_disk_bytes
--NOTE: when pass in NULLs we are saying "tell me about everybody"
FROM sys.dm_io_virtual_file_stats(NULL,NULL) ioFS
JOIN master.sys.master_files MF
	ON ioFS.database_id = MF.database_id
	AND ioFS.file_id = MF.file_id
ORDER BY
	4 DESC;

--use / look for Glenn Berry sql server diagnostic queries
--http://www.sqlskills.com/blogs/glenn/category/dmv-queries/
--also found here, but use the above https://sqlserverperformance.wordpress.com/category/diagnostic-queries/

/*
red flag query operators:
- lookups
- scans
- spools
- parallelism operations

red flags elsewhere:
- dissimilar estimated vs actual row counts
- high physical reads
- missing statistics alarms
- large sort operations
- implicit data type conversions
*/

/*
patterns and anti-patterns
- WHERE IN vs WHERE EXISTS
- UNION vs UNION ALL
- WHERE {NOT IN | EXISTS} vs LEFT JOIN
- functions and calculations in WHERE or JOIN
*/

--SQL Sentry on YouTube https://www.youtube.com/user/SQLSentry/featured

--http://bit.ly/AB-cursors
--http://bit.ly/AB-NOTIN
	--dangerous if source column is NULLable

/*
Sub-queries

Question:
- how much has a custom spent for all time?
- when did they place their last order?
*/
--version 1... 
--	put a correlated subquery in the SELECT list
SELECT
	c.CustomerID,
	p.FirstName,
	p.LastName,
	(SELECT SUM(TotalDue) FROM Sales.SalesOrderHeader WHERE CustomerID = c.CustomerID) AS LifeTimeSales,
	(SELECT MAX(OrderDate) FROM Sales.SalesOrderHeader WHERE CustomerID = c.CustomerID) AS LastOrder
FROM Sales.Customer AS c
JOIN Person.Person AS p
	ON p.BusinessEntityID = c.PersonID;

--version 2...
--  since most people will realize the above would be very inefficient then they might do
--	the following which joins to the table and group by
SELECT
	c.CustomerID,
	p.FirstName,
	p.LastName,
	SUM(s.TotalDue) AS LifeTimeSales,
	MAX(s.OrderDate) AS LastOrder
FROM Sales.Customer AS c
JOIN Sales.SalesOrderHeader s
	ON s.CustomerID = c.CustomerID
JOIN Person.Person AS p
	ON p.BusinessEntityID = c.PersonID
GROUP BY
	c.CustomerID
	, p.FirstName
	, p.LastName;

--version 3
--	pre-aggregate with a CTE... why... kind of ugly to group by 
--	firstname and last name above... so a CTE is a nice way to avoid this
--	Is a CTE like a temp table? 
--		- basically it is an inline view
WITH c AS
(
	SELECT 
		c.CustomerID,
		c.PersonID,
		SUM(s.TotalDue) AS LifeTimeSales,
		MAX(s.OrderDate) AS LastOrder
	FROM Sales.Customer AS c
	JOIN Sales.SalesOrderHeader s
		ON s.CustomerID = c.CustomerID
	GROUP BY
		c.CustomerID
		, c.PersonID
)
SELECT 
	c.CustomerID,
	p.FirstName,
	p.LastName,
	c.LifeTimeSales,
	c.LastOrder
FROM c
JOIN Person.Person AS p
	ON c.PersonID = p.BusinessEntityID;

--version 4
-- "Window" CTE instead of grouping
WITH x AS
(
	SELECT
		c.CustomerID,
		c.PersonID,
		p.FirstName,
		p.LastName,
		SUM(s.TotalDue) OVER (
			PARTITION BY c.CustomerID) AS LifeTimeSales,
		s.OrderDate AS LastOrder,
		ROW_NUMBER() OVER (
			PARTITION BY c.CustomerID
			ORDER BY s.OrderDate DESC) AS rn_ByDate
	FROM Sales.Customer AS c
	JOIN Sales.SalesOrderHeader s
		ON s.CustomerID = c.CustomerID
	JOIN Person.Person AS p
		ON p.BusinessEntityID = c.PersonID
)
SELECT
	CustomerID,
	FirstName,
	LastName,
	LifeTimeSales,
	LastOrder 
FROM x
WHERE
	rn_ByDate = 1;


/*
NOT IN
*/

--option 1... this is not great for performance and b/c it is problematic if CustomerID 
--	happens to have NULL values
SELECT CustomerID
FROM Sales.Customer
WHERE
	CustomerID NOT IN
	(
		SELECT CustomerID
		FROM Sales.SalesOrderHeader
	);

--option 2... NOT EXISTS... can short circuit! very worse is will perform the same
SELECT CustomerID
FROM Sales.Customer C
WHERE
	NOT EXISTS
	(
		SELECT 1
		FROM Sales.SalesOrderHeader S
		WHERE 
			S.CustomerID = C.CustomerID
	);

--option 3... EXCEPT... in a lot of cases cannot do this since except has to look the same
--but from a performance perspective it may be worse since does a DISTINCT on results (verify this)
SELECT CustomerID
FROM Sales.Customer
EXCEPT
SELECT CustomerID
FROM Sales.SalesOrderHeader;

--option 4... LEFT OUTER JOIN
SELECT 
	C.CustomerID
FROM Sales.Customer C
LEFT JOIN Sales.SalesOrderHeader S
	ON C.CustomerID = S.CustomerID
WHERE
	S.CustomerID IS NULL; --key used during the join

SELECT 
	C.CustomerID
FROM Sales.Customer C
LEFT JOIN Sales.SalesOrderHeader S
	ON C.CustomerID = S.CustomerID
WHERE
	S.SalesOrderID IS NULL; --primary key of table

/*
UNION vs UNION ALL
- UNION eliminates duplicates by sorting
	- requires a worktable and additional sort operations (maybe... a DISTINCT sort... not always though)
	- i.e. when Microsoft implemented UNION they made the default the ANSI standard "UNION DISTINCT"
*/

/*
CREATE INDEX first_last_type ON Person.Person(FirstName, LastName, PersonType);
CREATE INDEX last_first_type ON Person.Person(LastName, FirstName, PersonType);
CREATE INDEX type_last_first ON Person.Person(PersonType, LastName, FirstName);
*/	
DECLARE
	@PersonType	NCHAR(2) = N'IN', --N'VC'
	@LastName NVARCHAR(255) = N'Diaz', --N'Dillon'
	@FirstInitial NVARCHAR(255) = N'A' --N'Q'
	;

--same query... same results... 

--some people stop optimizing at first index seek
--but wait... this is NOT the case since FIRST is not 
SELECT
	FirstName, LastName, PersonType
FROM Person.Person WITH (INDEX = first_last_type)
WHERE
	PersonType = @PersonType
	AND LastName = @LastName
	AND FirstName LIKE @FirstInitial + '%';

SELECT
	FirstName, LastName, PersonType
FROM Person.Person WITH (INDEX = last_first_type)
WHERE
	PersonType = @PersonType
	AND LastName = @LastName
	AND FirstName LIKE @FirstInitial + '%';

SELECT
	FirstName, LastName, PersonType
FROM Person.Person WITH (INDEX = type_last_first)
WHERE
	PersonType = @PersonType
	AND LastName = @LastName
	AND FirstName LIKE @FirstInitial + '%';

SELECT
	FirstName, LastName, PersonType
FROM Person.Person WITH (INDEX = type_last_first)
WHERE
	LastName = @LastName
	AND FirstName LIKE @FirstInitial + '%';

DROP INDEX Person.Person.first_last_type;
DROP INDEX Person.Person.last_first_type;
DROP INDEX Person.Person.type_last_first;

/*
Covering index
*/
DROP INDEX Person.Person.ix_PersonName_Include
SELECT
	FirstName, LastName, P.ModifiedDate
FROM Person.Person P
WHERE
	LastName LIKE 'S%';

CREATE NONCLUSTERED INDEX ix_PersonName_Include
ON Person.Person(LastName, FirstName);

--seek... with lookup to attain rest of data
SELECT
	FirstName, LastName, P.ModifiedDate
FROM Person.Person P WITH (INDEX = ix_PersonName_Include)
WHERE
	LastName LIKE 'S%';

DROP INDEX Person.Person.ix_PersonName_Include;

CREATE NONCLUSTERED INDEX ix_PersonName_Include
ON Person.Person(LastName, FirstName, ModifiedDate);

SELECT
	FirstName, LastName, P.ModifiedDate
FROM Person.Person P
WHERE
	LastName LIKE 'S%';
--now will be a pure seek

DROP INDEX Person.Person.ix_PersonName_Include;

CREATE NONCLUSTERED INDEX ix_PersonName_Include
ON Person.Person(LastName, FirstName)
INCLUDE (ModifiedDate); --means that does not include column while collecting statistics

SELECT
	FirstName, LastName, P.ModifiedDate
FROM Person.Person P
WHERE
	LastName LIKE 'S%';
--also pure seek

/*
Optimizing for SELECT vs DML

http://bit.ly/AB-BlindIndex
*/

/*
What's the usage of an index?
- easy to answer with 2 DMV's
	sys.dm_db_index_physical_stats: actual on disk characteristics of indexes
	sys.dm_db_index_usage_stats: looking at from a higher level, how many scans, etc
*/

