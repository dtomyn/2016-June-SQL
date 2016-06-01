/*
Overview:
Demonstrates how IN and OR results in same query plan
*/
USE AdventureWorks2014;
GO

SELECT SalesOrderNumber
FROM Sales.SalesOrderHeader
WHERE
	SalesOrderNumber IN
	(
		N'SO43662'
		,N'SO43670'
		,N'SO43674'
	);

SELECT SalesOrderNumber
FROM Sales.SalesOrderHeader
WHERE
	SalesOrderNumber = N'SO43662'
	OR
	SalesOrderNumber = N'SO43670'
	OR
	SalesOrderNumber = N'SO43674'
	;

--some people have said that union will be better b/c of a "tipping point"
--"outsmart the optimizer"
SELECT SalesOrderNumber
FROM Sales.SalesOrderHeader
WHERE
	SalesOrderNumber = N'SO43662'
UNION 
SELECT SalesOrderNumber
FROM Sales.SalesOrderHeader
WHERE
	SalesOrderNumber = N'SO43670'
UNION 
SELECT SalesOrderNumber
FROM Sales.SalesOrderHeader
WHERE
	SalesOrderNumber = N'SO43674'
	;

SELECT SalesOrderNumber
FROM Sales.SalesOrderHeader
WHERE
	SalesOrderNumber = N'SO43662'
UNION ALL
SELECT SalesOrderNumber
FROM Sales.SalesOrderHeader
WHERE
	SalesOrderNumber = N'SO43670'
UNION ALL
SELECT SalesOrderNumber
FROM Sales.SalesOrderHeader
WHERE
	SalesOrderNumber = N'SO43674'
	;

