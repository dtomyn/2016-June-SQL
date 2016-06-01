USE AdventureWorks2014
GO
--    drop table #TestMe
	
	CREATE TABLE #TestMe  (
      i INT IDENTITY PRIMARY KEY CLUSTERED,
      City VARCHAR(60),
      StateProvinceID INT,
      INDEX ixTestMe_StateProvinceID NONCLUSTERED (StateProvinceID)
    );
    INSERT #TestMe (City,StateProvinceID)
    SELECT City, StateProvinceID
    FROM Person.Address;
    GO
    --This gets a nested loop plan
    SELECT City
    FROM #TestMe
    WHERE StateProvinceID=1;

	/*
	For the temporary table, SQL Server uses statistics associated with the nonclustered index to estimate that it will get 25 rows back (which is right on). Based on this it decides to seek to the rows in the nonclustered index, then do a nested loop lookup to fetch the City column from the clustered index. It does 52 logical reads:
	*/

	DECLARE @TestMe TABLE (
      i INT IDENTITY PRIMARY KEY CLUSTERED (i),
      City VARCHAR(60),
      StateProvinceID INT,
      INDEX ixTestMe_StateProvinceID NONCLUSTERED (StateProvinceID)
    );
    INSERT @TestMe (City,StateProvinceID)
    SELECT City, StateProvinceID
    FROM Person.Address;
    --This gets a clustered index scan
    SELECT City
    FROM @TestMe
    WHERE StateProvinceID=1;
    GO

	/*
Oddly enough, it gets a clustered index scan. It estimates that only one row will be found — that’s because for table variables, statistics associated with the nonclustered index still can’t be populated. So it doesn’t know to estimate the 25 rows, and it just guesses one.

With a one row estimate, I thought the optimizer would surely go for the nested loop lookup. Looking up just one row is easy, right? But instead it decided to scan the clustered index
	*/

	/*
	see the following for another potential "fix" to table variables
	http://sqlperformance.com/2014/06/t-sql-queries/table-variable-perf-fix
	*/