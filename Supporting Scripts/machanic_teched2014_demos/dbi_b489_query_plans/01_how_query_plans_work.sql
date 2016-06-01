USE AdventureWorks2014
GO



--Index scan -- reads the whole table?
SELECT 
	*
FROM Production.Product
GO

--what's a clustered index scan?:
--	typical answer: reads all the rows from the table
--estimated cost:
--	metric used by query optimizer to determine stuff...
-- STOP focusing on "cost" it means nothing to us!!!

--What really controls a scan?
SELECT TOP(100)
	*
FROM Production.Product
GO

--but wait... the above will result in an "actual number of rows" of 100 not all rows in table
--so... what is going on here?
--scan does NOT read all rows off of the table necessarily
--



--Insight: Number of Executions
SELECT TOP(1000)
	p.ProductId,
	th.TransactionId
FROM Production.Product AS p
INNER LOOP JOIN Production.TransactionHistory AS th WITH (FORCESEEK) ON
	p.ProductId = th.ProductId
WHERE
	th.ActualCost > 50
	AND p.StandardCost < 10
GO










