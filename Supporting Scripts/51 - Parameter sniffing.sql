/*
Overview:
Simplistic but good demonstration of what "parameter sniffing" is
and how to remove it (if it is causing issues)

NOTES:
- 80 is seek (4 rows)
- 79 is scan (48 rows)
*/
USE AdventureWorks2014;
GO


--first... using literals, show 2 queries

--this one will be an index seek
--and a key lookup for the rest of the data
SELECT DISTINCT City
FROM Person.Address
WHERE
	StateProvinceID = 80;

--this one will be an index scan
--why? b/c lots of rows and it doesn't
--make sense to do a key lookup for rest of data
--...this is actually good!
SELECT DISTINCT City
FROM Person.Address
WHERE
	StateProvinceID = 79;

/*************
**************
*************/

--before going further though, let's run
--the query with and without DISTINCT to
--see something else that SQL Server does
SELECT DISTINCT City
FROM Person.Address
WHERE
	StateProvinceID = 80;

SELECT City
FROM Person.Address
WHERE
	StateProvinceID = 80;

--notice that for the 2nd query the "80" turned into @1
--this is what is called "auto parameterization"

--what SQL Server is trying to do is to make this very simple
--execution plan something that can be reused by others

/*****************
******************
*****************/

/*
Remember...
- 80 s/b seek (4 rows)
- 79 s/b scan (48 rows)
*/

CHECKPOINT;
DBCC DROPCLEANBUFFERS;
DBCC FREEPROCCACHE WITH NO_INFOMSGS;

DECLARE @StateProvinceID INT = 80
SELECT DISTINCT City
FROM Person.Address
WHERE
	StateProvinceID = @StateProvinceID;
GO

DECLARE @StateProvinceID INT = 79
SELECT DISTINCT City
FROM Person.Address
WHERE
	StateProvinceID = @StateProvinceID;
GO

--both are now the SAME query plan!!!
--hmmm...
--estimated rows for each was 265??
--continuing on (and will revisit the above later)

CHECKPOINT;
DBCC DROPCLEANBUFFERS;
DBCC FREEPROCCACHE WITH NO_INFOMSGS;

IF OBJECT_ID('dbo.ucp_s_Cities_ByStateProvinceId') IS NULL
	EXEC ('CREATE PROCEDURE dbo.ucp_s_Cities_ByStateProvinceId AS RETURN 0');
GO

ALTER PROCEDURE dbo.ucp_s_Cities_ByStateProvinceId
	@StateProvinceID INT
AS
SELECT DISTINCT City
FROM Person.Address
WHERE
	StateProvinceID = @StateProvinceID;
GO

/*
Remember...
- 80 s/b seek (4 rows)
- 79 s/b scan (48 rows)
*/

EXEC dbo.ucp_s_Cities_ByStateProvinceId @StateProvinceID=80;
EXEC dbo.ucp_s_Cities_ByStateProvinceId @StateProvinceID=79;
--!!!!!!*******!!!!!!*****!!!!!
--******THIS is parameter sniffing
--!!!!!!*******!!!!!!*****!!!!!

--right-click the plan and choose "Show Execution Plan Xml..." and scroll all the way to the bottom
--and you will see this...
/*
            <ParameterList>
              <ColumnReference Column="@StateProvinceID" ParameterCompiledValue="(80)" ParameterRuntimeValue="(79)" />
            </ParameterList>
*/


--one solution we have tried in the past is assigning to local variables...

IF OBJECT_ID('dbo.ucp_s_Cities_ByStateProvinceId2') IS NULL
	EXEC ('CREATE PROCEDURE dbo.ucp_s_Cities_ByStateProvinceId2 AS RETURN 0');
GO

ALTER PROCEDURE dbo.ucp_s_Cities_ByStateProvinceId2
	@StateProvinceID INT
AS
DECLARE @_StateProvinceID INT = @StateProvinceID;
SELECT DISTINCT City
FROM Person.Address
WHERE
	StateProvinceID = @_StateProvinceID;
GO

/*
Remember...
- 80 s/b seek (4 rows)
- 79 s/b scan (48 rows)
*/

EXEC dbo.ucp_s_Cities_ByStateProvinceId2 @StateProvinceID=80;
EXEC dbo.ucp_s_Cities_ByStateProvinceId2 @StateProvinceID=79;

--nope... it is that "265 row" estimate again???

--how can we REALLY fix this then if this is a perf issue?
--1) while CALLING the stored procedure we can ask it to recompile

/*
Remember...
- 80 s/b seek (4 rows)
- 79 s/b scan (48 rows)
*/

EXEC dbo.ucp_s_Cities_ByStateProvinceId @StateProvinceID=80 WITH RECOMPILE;
EXEC dbo.ucp_s_Cities_ByStateProvinceId @StateProvinceID=79 WITH RECOMPILE;

--but... this is a HORRIBLE idea. Now they will never be in cache and you can't use DMVs to figure out
--worst performing queries

--2) if you really really really really like the plan for 80 (for example)
--you can do this
ALTER PROCEDURE dbo.ucp_s_Cities_ByStateProvinceId
	@StateProvinceID INT
AS
SELECT DISTINCT City
FROM Person.Address
WHERE
	StateProvinceID = @StateProvinceID
	OPTION (OPTIMIZE FOR (@StateProvinceID=80));
GO

/*
Remember...
- 80 s/b seek (4 rows)
- 79 s/b scan (48 rows)
*/
CHECKPOINT;
DBCC DROPCLEANBUFFERS;
DBCC FREEPROCCACHE WITH NO_INFOMSGS;

EXEC dbo.ucp_s_Cities_ByStateProvinceId @StateProvinceID=79;
EXEC dbo.ucp_s_Cities_ByStateProvinceId @StateProvinceID=80;

--3) you can also optimize for an "anonymous" value... kinda odd
ALTER PROCEDURE dbo.ucp_s_Cities_ByStateProvinceId
	@StateProvinceID INT
AS
SELECT DISTINCT City
FROM Person.Address
WHERE
	StateProvinceID = @StateProvinceID
	OPTION (OPTIMIZE FOR UNKNOWN);
GO

/*
Remember...
- 80 s/b seek (4 rows)
- 79 s/b scan (48 rows)
*/
EXEC dbo.ucp_s_Cities_ByStateProvinceId @StateProvinceID=80;
EXEC dbo.ucp_s_Cities_ByStateProvinceId @StateProvinceID=79;

--the 265 is back...

--What is this? short of it is it is the "average" rows that an "average" value will return
--more specifically... it is the statistical probability of rows for any value
--...what is the "general distribution" of it

--it DOES give you *consistency* in execution which might be all that you are looking for!!!

--digging into this some more...
DBCC FREEPROCCACHE;
GO


--3b
ALTER PROCEDURE dbo.ucp_s_Cities_ByStateProvinceId
	@StateProvinceID INT
AS
SELECT DISTINCT City
FROM Person.Address
WHERE
	StateProvinceID = @StateProvinceID
	OPTION (OPTIMIZE FOR UNKNOWN
		,QUERYTRACEON 3604 
		--for sql 2012
		--,QUERYTRACEON 9204
		--for sql 2014
		,QUERYTRACEON 2363 --**see: http://sqlperformance.com/2014/01/sql-plan/cardinality-estimation-for-multiple-predicates
		);
	--shows you what statistics it is using when it is CREATING the optimized execution plan
GO

EXEC dbo.ucp_s_Cities_ByStateProvinceId @StateProvinceID=80;
EXEC dbo.ucp_s_Cities_ByStateProvinceId @StateProvinceID=79;

--notice how it is using indexid 4 - the StateProvinceID index
--i.e.
SELECT si.name 
FROM sys.indexes si
WHERE 
	si.index_id = 4
	AND si.object_id = OBJECT_ID('Person.Address');

--so... use dbcc show_statistics to get the histogram of how stats are stored
DBCC SHOW_STATISTICS('Person.Address', 'IX_Address_StateProvinceID')

--this shows:
-- - when table last updated
-- - how many rows were there and how many rows sampled 
--			19614
-- - in 2nd resultset it has an "all density" of 0.01351351 that is a statistical probability of any particular value
--			0.01351351
SELECT 19614 * 0.01351351

--...and this is our "265" value

--4) adding option recompile to entire PROC
ALTER PROCEDURE dbo.ucp_s_Cities_ByStateProvinceId
	@StateProvinceID INT
	WITH RECOMPILE
AS
SELECT DISTINCT City
FROM Person.Address
WHERE
	StateProvinceID = @StateProvinceID;
GO

EXEC dbo.ucp_s_Cities_ByStateProvinceId @StateProvinceID=80;
EXEC dbo.ucp_s_Cities_ByStateProvinceId @StateProvinceID=79;

--although this works... we can now even do one better and be more granula

--5) adding option recompile to a STATEMENT

ALTER PROCEDURE dbo.ucp_s_Cities_ByStateProvinceId
	@StateProvinceID INT
AS
SELECT DISTINCT City
FROM Person.Address
WHERE
	StateProvinceID = @StateProvinceID
OPTION (RECOMPILE);
GO

EXEC dbo.ucp_s_Cities_ByStateProvinceId @StateProvinceID=80;
EXEC dbo.ucp_s_Cities_ByStateProvinceId @StateProvinceID=79;

--dbcc show_statistics('Person.Person','PK_Person_BusinessEntityID')