/*
Overview:
Demonstrates the difference between IN/EXISTS and NOT IN/NOT EXISTS
Also shows EXCEPT... and how probably would be rarely used
*/
SET NOCOUNT ON;

IF NOT OBJECT_ID('tempdb..#Customer') IS NULL
BEGIN
	DROP TABLE #Customer;
END

CREATE TABLE #Customer 
(
	ID INT IDENTITY(1,1) PRIMARY KEY,
	CustomerID INT NULL
);

INSERT #Customer 
VALUES
	(1),
	(10),
	(NULL) --on purpose BAD DATA!!!
	--scenario? perhaps this is a column where user enters in a business key and you left it NULLable
	;

IF NOT OBJECT_ID('tempdb..#Order') IS NULL
BEGIN
	DROP TABLE #Order;
END

CREATE TABLE #Order 
(
	ID INT IDENTITY(1,1) PRIMARY KEY
	, CustomerID_Fk INT NOT NULL
);

INSERT #Order 
VALUES
	(1),
	(1),
	(2), --on purpose BAD DATA!!!
	(2) --on purpose BAD DATA!!!
	--scenario? unfortunately many commercial databases lack foreign key constraints... so this could have been
	--	a scenario of someone deleting a customer that had orders but the orders remained
	;

SELECT 'This will show all customers that have orders... use "IN" seems reasonable enough...'

SELECT CustomerID_Fk 
FROM #Order 
WHERE 
	CustomerID_Fk IN 
	(
		SELECT CustomerID FROM #Customer
	);

SELECT 'Next... lets try the opposite and show all orders that do not have a customer...'

SELECT 'The next set tries a "NOT IN"... i.e. opposite of IN approach... would expect 2 rows... right???...'

SELECT CustomerID_Fk 
FROM #Order 
WHERE 
	CustomerID_Fk NOT IN 
	(
		SELECT CustomerID FROM #Customer
	);

SELECT '...NULL complicates things when it comes to NOT IN. First, looking at IN this can actually return TRUE, FALSE and NULL... so the IN worked since looking for all TRUE'
SELECT 'However, NOT IN looks for all false and since a negation of NULL is NULL then this comparison will never return false and therefore overall result will never return correct value of 2 since unknown'

SELECT 'So... solution is to use EXISTS!... EXISTS always returns TRUE / FALSE... as does NOT EXISTS'

SELECT CustomerID_Fk
FROM #Order as [Order]
WHERE 
	NOT EXISTS
	(
		SELECT 1 
		FROM #Customer AS Customer
		WHERE Customer.CustomerID = [Order].CustomerID_Fk
	);

SELECT 'You can also use something called EXCEPT which is relatively new with SQL Server but know that this is the same as UNION where it will do a DISTINCT before returning...'

--relatively new to sql server is the EXCEPT operator
--...but... this does a DISTINCT sort
SELECT CustomerID_Fk
FROM #Order
EXCEPT 
SELECT CustomerID
FROM #Customer;

SELECT 'Of course, another option is to use LEFT JOIN and IS NULL check... HOWEVER, this will cost more since returning all data from order customer and then filtering (conceptually)'

SELECT CustomerID_Fk
FROM #Order
LEFT JOIN #Customer
	ON CustomerID = CustomerID_Fk
WHERE
	CustomerID IS NULL;
GO

SELECT 'To demonstrate efficiency of NOT EXISTS vs LEFT JOIN / IS NULL... lets add a bunch more data into customer...'

INSERT INTO #Customer
SELECT s1.column_id FROM sys.all_columns AS s1 
CROSS JOIN (SELECT n FROM (VALUES(1), (2), (3), (4)) AS s(n)) AS n1 
CROSS JOIN (SELECT n FROM (VALUES(1), (2), (3), (4)) AS s(n)) AS n2 
CROSS JOIN (SELECT n FROM (VALUES(1), (2), (3), (4)) AS s(n)) AS n3;

SELECT @@ROWCOUNT [More Customers added]

DELETE FROM #Customer WHERE CustomerID = 2

SELECT @@ROWCOUNT [Removed the CustomerID = 2 records again]

SELECT COUNT(*) [Customers Left Over] FROM #Customer
GO

SELECT 'Run the above plus the below at same time to view comparison of execution plans better...'

SELECT CustomerID_Fk
FROM #Order
LEFT JOIN #Customer
	ON CustomerID = CustomerID_Fk
WHERE
	CustomerID IS NULL;
GO

SELECT CustomerID_Fk
FROM #Order as [Order]
WHERE 
	NOT EXISTS
	(
		SELECT 1 
		FROM #Customer AS Customer
		WHERE Customer.CustomerID = [Order].CustomerID_Fk
	);
