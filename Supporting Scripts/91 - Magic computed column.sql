/*
Overview:
If there is an index on a computed column and there is a query that looks exactly like the 
computed column, then SQL Server is smart enough to USE the computed column!
The below script shows exactly this by using the TotalDue column

*/
USE AdventureWorks2014;

SET NOCOUNT ON
GO
DROP INDEX Sales.SalesOrderHeader.SalesOrderHeader_TotalDue
GO

SELECT 
	SalesOrderID,
	ISNULL(SubTotal+TaxAmt+Freight,0)
FROM Sales.SalesOrderHeader;
GO

--but there is a computed column...
--so... index it...
CREATE INDEX SalesOrderHeader_TotalDue
ON Sales.SalesOrderHeader(TotalDue)
INCLUDE (SalesOrderID);
GO

SELECT 
	SalesOrderID,
	ISNULL(SubTotal+TaxAmt+Freight,0)
FROM Sales.SalesOrderHeader;
GO

--even though did NOT ask for computed column
--SQL Server can use them!!

--better yet...
SELECT 
	SalesOrderID,
	ISNULL(SubTotal+TaxAmt+Freight,0)
FROM Sales.SalesOrderHeader
WHERE
	ISNULL(SubTotal+TaxAmt+Freight,0) > 100;
GO

--INDEX SEEK!!!!