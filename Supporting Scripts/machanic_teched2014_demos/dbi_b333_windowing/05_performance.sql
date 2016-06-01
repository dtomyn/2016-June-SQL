USE AdventureWorks
GO




--Prepare a temp table
SELECT
	*
INTO #bth
FROM bigTransactionHistory AS bh
WHERE
	ProductId BETWEEN 1001 AND 5001
GO



--Enable actual query plan



--Use the temp table to do a running sum...
--note the cost of the sort!
SELECT 
	th.ProductId,
	th.TransactionId,
	th.TransactionDate,
	th.Quantity,
	SUM(th.ActualCost) OVER 
	(
		PARTITION BY
			th.ProductId
		ORDER BY 
			th.TransactionId
	) AS qtyRunningSum
INTO #x1
FROM #bth AS th
WHERE
	Quantity > 0
GO




--POC indexing
CREATE INDEX i_POC
ON #bth
(
	--Partitioning
	ProductId,
	--Ordering
	TransactionId
)
INCLUDE
(
	--Covering
	TransactionDate,
	ActualCost,
	Quantity
)
GO




--Try again...
SELECT 
	th.ProductId,
	th.TransactionId,
	th.TransactionDate,
	th.Quantity,
	SUM(th.ActualCost) OVER 
	(
		PARTITION BY
			th.ProductId
		ORDER BY 
			th.TransactionId
	) AS qtyRunningSum
INTO #x2
FROM #bth AS th
WHERE
	Quantity > 0
GO




--FPOC Index ?
CREATE INDEX i_FPOC
ON #bth
(
	--Filtering
	Quantity,
	--Partitioning
	ProductId,
	--Ordering
	TransactionId
)
INCLUDE
(
	--Covering
	TransactionDate,
	ActualCost
)
GO




--The new index isn't good enough?!
SELECT 
	th.ProductId,
	th.TransactionId,
	th.TransactionDate,
	th.Quantity,
	SUM(th.ActualCost) OVER 
	(
		PARTITION BY
			th.ProductId
		ORDER BY 
			th.TransactionId
	) AS qtyRunningSum
INTO #x3
FROM #bth AS th
WHERE
	Quantity > 0
GO




--Try a totally new way to write the query...


--First take the product IDs from the temp table
SELECT DISTINCT
	ProductId
INTO #products
FROM #bth
GO



--Now drive the query on those IDs
SELECT
	p.ProductId,
	v.*
INTO #x4
FROM #products AS p
CROSS APPLY
(
	SELECT 
		th.TransactionId,
		th.TransactionDate,
		th.Quantity,
		SUM(th.ActualCost) OVER 
		(
			ORDER BY 
				th.TransactionId
		) AS qtyRunningSum
	FROM #bth AS th
	WHERE
		th.Quantity > 0
		AND th.ProductID = p.ProductID
) AS v
WHERE
	p.ProductID BETWEEN 1001 AND 5001
GO




--Don't forget ROWS mode!!!
SELECT
	p.ProductId,
	v.*
INTO #x5
FROM #products AS p
CROSS APPLY
(
	SELECT 
		th.TransactionId,
		th.TransactionDate,
		th.Quantity,
		SUM(th.ActualCost) OVER 
		(
			ORDER BY 
				th.TransactionId
			ROWS UNBOUNDED PRECEDING
		) AS qtyRunningSum
	FROM #bth AS th
	WHERE
		th.Quantity > 0
		AND th.ProductID = p.ProductID
) AS v
WHERE
	p.ProductID BETWEEN 1001 AND 5001
GO




--Optional



--Partitioned MIN/MAX and the Window Spool


--Find all transactions where the product sold within the top 5% of all sales for that product
SELECT
	v.*
INTO #y1
FROM
(
	SELECT
		th.TransactionID,
		th.TransactionDate,
		th.ProductID,
		MAX(th.ActualCost) OVER 
		(
			PARTITION BY 
				th.ProductId
		) AS maxCost,
		ActualCost
	FROM dbo.bigTransactionHistory AS th
	WHERE
		th.ProductID BETWEEN 1001 AND 8001
		AND th.ActualCost > 0
) AS v
WHERE
	v.ActualCost >= 0.95 * v.maxCost
GO




--Think about MAX... what set of rows do we need to look at?
--And wouldn't it be nice to use ROWS mode?
SELECT
	v.*
INTO #y2
FROM
(
	SELECT
		th.TransactionID,
		th.TransactionDate,
		th.ProductID,
		MAX(th.ActualCost) OVER 
		(
			PARTITION BY 
				th.ProductId
			ORDER BY
				th.ActualCost DESC
			ROWS UNBOUNDED PRECEDING
		) AS maxCost,
		ActualCost
	FROM dbo.bigTransactionHistory AS th
	WHERE
		th.ProductID BETWEEN 1001 AND 8001
		AND th.ActualCost > 0
) AS v
WHERE
	v.ActualCost >= 0.95 * v.maxCost
GO




