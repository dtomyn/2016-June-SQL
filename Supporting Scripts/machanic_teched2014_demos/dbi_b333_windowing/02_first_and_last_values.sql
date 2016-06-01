USE AdventureWorks2014
GO




--"Last" row per month -- the really old way
SELECT
	x.TransactionMonth,
	x.ProductID,
	x.LastDate,
	th1.ActualCost AS LastCost
FROM
(
	SELECT
		MAX(th.TransactionDate) AS LastDate,
		EOMONTH(th.TransactionDate) AS TransactionMonth,
		th.TransactionID,
		th.ProductID
	FROM Production.TransactionHistory AS th
	GROUP BY
		EOMONTH(th.TransactionDate),
		th.TransactionID,
		th.ProductID
) AS x
INNER JOIN Production.TransactionHistory AS th1 ON
	th1.ProductID = x.ProductID
	AND th1.TransactionDate = x.LastDate
	AND th1.TransactionID = x.TransactionID
ORDER BY
	ProductId,
	TransactionMonth
GO




--Using ROW_NUMBER (2005+) to solve the "TOP N Per Group" problem
SELECT
	y.TransactionMonth,
	y.ProductID,
	y.TransactionDate AS LastDate,
	y.ActualCost AS LastCost
FROM
(
	SELECT
		x.*,
		ROW_NUMBER() OVER
		(
			PARTITION BY 
				x.TransactionMonth,
				x.ProductID
			ORDER BY
				x.TransactionDate DESC
		) AS isLastRow
	FROM
	(
		SELECT
			th.TransactionDate,
			EOMONTH(th.TransactionDate) AS TransactionMonth,
			th.ProductID,
			th.ActualCost
		FROM Production.TransactionHistory AS th
	) AS x
) AS y
WHERE
	y.isLastRow = 1
ORDER BY
	y.ProductId,
	y.TransactionMonth
GO




--Add additional information (2012+): What happened during the month?
SELECT
	y.TransactionMonth,
	y.ProductID,
	y.FirstDate,
	y.FirstCost,
	y.TransactionDate AS LastDate,
	y.ActualCost AS LastCost
FROM
(
	SELECT
		x.*,
		FIRST_VALUE(x.TransactionDate) OVER
		(
			PARTITION BY 
				x.TransactionMonth,
				x.ProductID
			ORDER BY
				x.TransactionDate
		) AS FirstDate,
		FIRST_VALUE(x.ActualCost) OVER
		(
			PARTITION BY 
				x.TransactionMonth,
				x.ProductID
			ORDER BY
				x.TransactionDate
		) AS FirstCost,
		ROW_NUMBER() OVER
		(
			PARTITION BY 
				x.TransactionMonth,
				x.ProductID
			ORDER BY
				x.TransactionDate DESC
		) AS isLastRow
	FROM
	(
		SELECT
			th.TransactionDate,
			EOMONTH(th.TransactionDate) AS TransactionMonth,
			th.ProductID,
			th.ActualCost
		FROM Production.TransactionHistory AS th
	) AS x
) AS y
WHERE
	y.isLastRow = 1
ORDER BY
	y.ProductId,
	y.TransactionMonth
GO



--LAST_VALUE is a bit weird...
SELECT
	Name,
	FIRST_VALUE(Name) OVER
	(
		ORDER BY
			ProductId
	) AS first_name,
	LAST_VALUE(Name) OVER
	(
		ORDER BY
			ProductId
	) AS last_name
FROM Production.Product
GO




--Solution #1
--Set a proper window frame!
SELECT
	Name,
	FIRST_VALUE(Name) OVER
	(
		ORDER BY
			ProductId
	) AS first_name,
	LAST_VALUE(Name) OVER
	(
		ORDER BY
			ProductId
		ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING
	) AS last_name
FROM Production.Product
GO




--Solution #2
--What is a LAST_VALUE? Perhaps a backward FIRST_VALUE?
SELECT
	Name,
	FIRST_VALUE(Name) OVER
	(
		ORDER BY
			ProductId
	) AS first_name,
	FIRST_VALUE(Name) OVER
	(
		ORDER BY
			ProductId DESC
	) AS last_name
FROM Production.Product
GO






