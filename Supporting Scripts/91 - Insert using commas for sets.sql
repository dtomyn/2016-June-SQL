/*
Overview:
Demonstrates inserting lots of data using "comma sets"
*/

IF NOT OBJECT_ID('tempdb..#x') IS NULL 
	DROP TABLE #x; 

CREATE TABLE #x 
(
	id INT IDENTITY(1,1),
	a INT,
	b INT
); 

INSERT INTO #x 
VALUES 
	(10, 20),
	(20, 30),
	(30, 40); 

SELECT * 
FROM #x; 
 
