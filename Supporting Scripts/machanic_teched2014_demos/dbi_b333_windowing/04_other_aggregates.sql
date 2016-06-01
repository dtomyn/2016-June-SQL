USE AdventureWorks
GO




--Moving average of last quarter's performance..?
SELECT
	x.*,
	AVG(x.TotalCost) OVER 
	(
		PARTITION BY 
			x.ProductId 
		ORDER BY 
			x.TransactionMonth 
		ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
	) AS movingAvgLastQtr
FROM
(
	SELECT
		th.ProductId,
		EOMONTH(th.TransactionDate) AS TransactionMonth,
		SUM(th.ActualCost) AS TotalCost
	FROM Production.TransactionHistory AS th
	GROUP BY
		th.ProductId,
		EOMONTH(th.TransactionDate)
) AS x
ORDER BY
	x.ProductId,
	x.TransactionMonth
GO


--Check ProductIDs 366, 367, 368, ... --> December, 2003




--Fix the gaps?
--One method: Send back NULL when we have 3 nonconsecutive prior periods
SELECT
	y.ProductID,
	y.TransactionMonth,
	y.TotalCost,
	CASE
		WHEN 
			y.numRowsInFrame < 3
			OR DATEDIFF(MONTH, y.firstMonthInFrame, y.TransactionMonth) = 2
				THEN y.movingAvgLastQtr
		ELSE
			NULL
	END AS movingAvgLastQtr
FROM
(
	SELECT
		x.*,
		AVG(x.TotalCost) OVER 
		(
			PARTITION BY 
				x.ProductId 
			ORDER BY 
				x.TransactionMonth 
			ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
		) AS movingAvgLastQtr,
		COUNT(*) OVER
		(
			PARTITION BY
				x.ProductId
			ORDER BY
				x.TransactionMonth 
			ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
		) AS numRowsInFrame,
		FIRST_VALUE(x.TransactionMonth) OVER
		(
			PARTITION BY
				x.ProductId
			ORDER BY
				x.TransactionMonth 
			ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
		) AS firstMonthInFrame
	FROM
	(
		SELECT
			th.ProductId,
			EOMONTH(th.TransactionDate) AS TransactionMonth,
			SUM(th.ActualCost) AS TotalCost
		FROM Production.TransactionHistory AS th
		GROUP BY
			th.ProductId,
			EOMONTH(th.TransactionDate)
	) AS x
) AS y
ORDER BY
	y.ProductId,
	y.TransactionMonth
GO




