USE AdventureWorks2014
GO




--Quantity Running Sum
--The "old" way
SELECT 
	th.ProductId,
	th.TransactionId,
	th.TransactionDate,
	th.Quantity,
	th.TransactionType,
	SUM(th1.Quantity) AS qtyRunningSum
FROM Production.TransactionHistory AS th
INNER JOIN Production.TransactionHistory AS th1 ON
	th1.TransactionID <= th.TransactionID
GROUP BY
	th.ProductId,
	th.TransactionId,
	th.TransactionDate,
	th.Quantity,
	th.TransactionType
GO




--The "new" way
SELECT 
	th.ProductId,
	th.TransactionId,
	th.TransactionDate,
	th.Quantity,
	th.TransactionType,
	SUM(th.Quantity) OVER 
	(
		ORDER BY 
			th.TransactionId
	) AS qtyRunningSum
FROM Production.TransactionHistory AS th
GO




--Expressiveness
--Calculate per product instead?
SELECT 
	th.ProductId,
	th.TransactionId,
	th.TransactionDate,
	th.Quantity,
	th.TransactionType,
	SUM(th.Quantity) OVER 
	(
		PARTITION BY
			th.ProductId
		ORDER BY 
			th.TransactionId
	) AS qtyRunningSumPerProduct
FROM Production.TransactionHistory AS th
GO




--Calculate both?
SELECT 
	th.ProductId,
	th.TransactionId,
	th.TransactionDate,
	th.Quantity,
	th.TransactionType,
	SUM(th.Quantity) OVER 
	(
		PARTITION BY
			th.ProductId
		ORDER BY 
			th.TransactionId
	) AS qtyRunningSumPerProduct,
	SUM(th.Quantity) OVER 
	(
		ORDER BY 
			th.TransactionId
	) AS qtyRunningSum
FROM Production.TransactionHistory AS th
GO




--Explore RANGE vs ROWS mode
SELECT 
	th.ProductId,
	th.TransactionId,
	th.TransactionDate,
	th.Quantity,
	th.TransactionType,
	SUM(th.Quantity) OVER 
	(
		ORDER BY 
			th.TransactionType /*a simple change?*/
	) AS qtyRunningSum
FROM Production.TransactionHistory AS th
GO




--Default window frame
SELECT 
	th.ProductId,
	th.TransactionId,
	th.TransactionDate,
	th.Quantity,
	th.TransactionType,
	SUM(th.Quantity) OVER 
	(
		ORDER BY 
			th.TransactionType
		/* 
			THIS IS THE DEFAULT! 
			DOES IT MAKE SENSE FOR YOUR QUERY?
		*/
		RANGE UNBOUNDED PRECEDING
	) AS qtyRunningSum
FROM Production.TransactionHistory AS th
GO




--Moral: ALWAYS use a tiebreaker
SELECT 
	th.ProductId,
	th.TransactionId,
	th.TransactionDate,
	th.Quantity,
	th.TransactionType,
	SUM(th.Quantity) OVER 
	(
		ORDER BY 
			th.TransactionType,
			th.TransactionId
		RANGE UNBOUNDED PRECEDING
	) AS qtyRunningSum
FROM Production.TransactionHistory AS th
GO




--ROWS mode changes everything...
SELECT 
	th.ProductId,
	th.TransactionId,
	th.TransactionDate,
	th.Quantity,
	th.TransactionType,
	SUM(th.Quantity) OVER 
	(
		ORDER BY 
			th.TransactionType
		ROWS UNBOUNDED PRECEDING
	) AS qtyRunningSum
FROM Production.TransactionHistory AS th
GO




--Configuring ROWS mode
SELECT 
	th.ProductId,
	th.TransactionId,
	th.TransactionDate,
	th.Quantity,
	th.TransactionType,
	SUM(th.Quantity) OVER 
	(
		ORDER BY 
			th.TransactionType
		ROWS BETWEEN 10 PRECEDING AND CURRENT ROW
	) AS qtyRunningSum
FROM Production.TransactionHistory AS th
GO




--Forward-looking window frame?
SELECT 
	th.ProductId,
	th.TransactionId,
	th.TransactionDate,
	th.Quantity,
	th.TransactionType,
	SUM(th.Quantity) OVER 
	(
		ORDER BY 
			th.TransactionType
		ROWS BETWEEN 10 PRECEDING AND 10 FOLLOWING
	) AS qtyRunningSum
FROM Production.TransactionHistory AS th
GO




--ROWS mode doesn't have to remember as much...

--Test it...
SET STATISTICS TIME ON
SET STATISTICS IO ON


--Note that the query plans are ALMOST identical, with identical costs...

SELECT 
	th.ProductId,
	th.TransactionId,
	th.TransactionDate,
	th.Quantity,
	th.TransactionType,
	SUM(th.Quantity) OVER 
	(
		ORDER BY 
			th.TransactionType,
			th.TransactionId
		RANGE UNBOUNDED PRECEDING
	) AS qtyRunningSum
FROM Production.TransactionHistory AS th
GO


SELECT 
	th.ProductId,
	th.TransactionId,
	th.TransactionDate,
	th.Quantity,
	th.TransactionType,
	SUM(th.Quantity) OVER 
	(
		ORDER BY 
			th.TransactionType,
			th.TransactionId
		ROWS UNBOUNDED PRECEDING
	) AS qtyRunningSum
FROM Production.TransactionHistory AS th
GO




--Another peek into Window Spool behavior...
--Try swapping 9998 to 9999
--(Luckily I have a fast SSD!)
SELECT 
	th.ProductId,
	th.TransactionId,
	th.TransactionDate,
	th.Quantity,
	th.TransactionType,
	SUM(th.Quantity) OVER 
	(
		ORDER BY 
			th.TransactionType,
			th.TransactionId
		ROWS BETWEEN 9998 PRECEDING AND CURRENT ROW
	) AS qtyRunningSum
FROM Production.TransactionHistory AS th
GO
