/*
Overview:
Common question I have seen answered varying ways is something like
"find all rows in table X that occurred on a particular date"
Answering this question is a good demonstration of importance
of doing things the right way... SARGable at its finest!!
*/
USE AdventureWorks2014;
GO

--Step 1 - drop index on table we are going to query if it already exists
--NOTE: I am also demonstrating how for EXISTS it doesn't matter what is in SELECT statement!

IF EXISTS(SELECT 1/0 FROM sys.indexes si WHERE si.name = 'x' AND si.object_id = OBJECT_ID('Sales.SalesOrderHeaderEnlarged'))
	DROP INDEX Sales.SalesOrderHeaderEnlarged.x;

--Step 2 - create the index that we want to see used
CREATE INDEX x ON Sales.SalesOrderHeaderEnlarged(OrderDate);

--Step 3 - show a couple of different ways of searching for a particular date
--	using "Include Actual Execution Plan" see how they all end up with an Index Scan
--	interestingly enough though... in order to answer the question, SQL Server is smart
--	enough to use the index mentioned above... uses what is called the "skinny index"
SELECT COUNT(*)
FROM Sales.SalesOrderHeaderEnlarged
WHERE
	YEAR(OrderDate) = 2011
	AND MONTH(OrderDate) = 5
	AND DAY(Orderdate) = 31;

SELECT COUNT(*)
FROM Sales.SalesOrderHeaderEnlarged
WHERE
	DATEDIFF(DAY, OrderDate, '20110531') = 0;

SELECT COUNT(*)
FROM Sales.SalesOrderHeaderEnlarged
WHERE
	CONVERT(CHAR(10), OrderDate, 110) = '05-31-2011';

--Step 4 - now the CORRECT way to do this
--	use open ended date range... NEVER BETWEEN as this will just cause issues
SELECT COUNT(*)
FROM Sales.SalesOrderHeaderEnlarged
WHERE
	OrderDate >= '20110531'
	AND OrderDate < '20110601';
--yay!!! an index seek!!!!

--new with SQL Server 2012 you can do the below which suprisingly works VERY EFFICIENTLY!!!!
--but... please do NOT do the below... its actually not documented!!!!!
SELECT COUNT(*)
FROM Sales.SalesOrderHeaderEnlarged
WHERE
	CONVERT(DATE, OrderDate) = DATEFROMPARTS(2011,5,31)
OPTION (RECOMPILE);

SELECT COUNT(*)
FROM Sales.SalesOrderHeaderEnlarged
WHERE
	CONVERT(DATE, OrderDate) = '20110531'
OPTION (RECOMPILE);
