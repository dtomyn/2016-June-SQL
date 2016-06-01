USE AdventureWorks
GO




--period-over-period delta with lag
SELECT
	x.*,
	LAG(x.TotalCost) OVER 
	(
		PARTITION BY 
			x.ProductId 
		ORDER BY 
			x.TransactionMonth 
	) AS totalCostLastMonth,
	x.TotalCost - 
		LAG(x.TotalCost) OVER 
		(
			PARTITION BY 
				x.ProductId 
			ORDER BY 
				x.TransactionMonth 
		) AS totalCostDelta
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




--other lag options
SELECT
	x.*,
	LAG
	(
		x.TotalCost,
		--number of rows to look back (basically a window frame)
		2,
		--no value? Want to default to something other than NULL?
		-100000
	) OVER
	(
		PARTITION BY 
			x.ProductId 
		ORDER BY 
			x.TransactionMonth 
	) AS totalCostLastMonth
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




--validation... is it really last month?
SELECT
	y.*
FROM
(
	SELECT
		x.*,
		LAG(x.TotalCost) OVER
		(
			PARTITION BY 
				x.ProductId 
			ORDER BY 
				x.TransactionMonth 
		) AS totalCostLastMonth,
		LAG(x.TransactionMonth) OVER
		(
			PARTITION BY 
				x.ProductId 
			ORDER BY 
				x.TransactionMonth 
		) AS LastMonth
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
WHERE
	DATEDIFF(MONTH, y.LastMonth, y.TransactionMonth) = 1
ORDER BY
	y.ProductId,
	y.TransactionMonth
GO




--simple date packing using SUM and LAG...

--Over which consecutive months did we sell products?
SELECT
	z.ProductID,
	MIN(z.TransactionMonth) AS startMonth,
	MAX(z.TransactionMonth) AS endMonth,
	SUM(z.totalCost) AS totalCost
FROM
(
	SELECT
		y.*,
		SUM(y.isStart) OVER
		(
			PARTITION BY 
				y.ProductId 
			ORDER BY 
				y.TransactionMonth 
		) AS intervalGroup
	FROM
	(
		SELECT
			x.*,
			CASE
				WHEN
					1 <>
						ISNULL
						(
							DATEDIFF
							(
								MONTH,
								LAG(x.TransactionMonth) OVER
								(
									PARTITION BY 
										x.ProductId 
									ORDER BY 
										x.TransactionMonth 
								),
								x.TransactionMonth
							),
							0
						)
						THEN 1
				ELSE 0
			END AS isStart
		FROM
		(
			SELECT
				th.ProductId,
				SUM(th.ActualCost) AS totalCost,
				EOMONTH(th.TransactionDate) AS TransactionMonth
			FROM Production.TransactionHistory AS th
			GROUP BY
				th.ProductId,
				EOMONTH(th.TransactionDate)
		) AS x
	) AS y
) AS z
GROUP BY
	ProductID,
	intervalGroup
ORDER BY
	ProductID,
	intervalGroup
GO




--Look forward? LEAD...
--dynamic "frame" of LAG/LEAD -- reach forward using a ROW_NUMBER
--What's the price on the first of NEXT month?
SELECT
	x.*,
	LEAD
	(
		ActualCost, 
		x.r
	) OVER 
	(
		PARTITION BY 
			x.ProductId 
		ORDER BY 
			x.TransactionMonth
	) AS t
FROM
(
	SELECT
		th.ProductId,
		th.ActualCost,
		th.TransactionDate AS TransactionMonth,
		th.TransactionId,
		--number of rows until next month
		ROW_NUMBER() OVER
		(
			PARTITION BY
				th.ProductId,
				EOMONTH(th.TransactionDate)
			ORDER BY
				th.TransactionId DESC
		) AS r
	FROM Production.TransactionHistory AS th
) AS x
GO

