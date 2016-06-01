/*
Overview:
Demonstrates how for EXISTS SELECT piece it does NOT matter what one puts there
as it is never executed
*/
SET NOCOUNT ON;
SET STATISTICS IO ON;
SET STATISTICS PROFILE ON;
SET STATISTICS TIME ON;

IF NOT OBJECT_ID('tempdb..#x') IS NULL  
    DROP TABLE #x;
GO 
CREATE TABLE #x (a INT);
INSERT INTO #x VALUES (1), (2); 
GO 
SELECT *   
FROM #x  
WHERE EXISTS (      
    SELECT * 
    FROM #x innerx 
    WHERE innerx.a = #x.a  
); 
GO 
SELECT *   
FROM #x  
WHERE EXISTS (      
    SELECT 1 
    FROM #x innerx 
    WHERE innerx.a = #x.a  
);
GO 
SELECT *   
FROM #x  
WHERE EXISTS (      
    SELECT NULL
    FROM #x innerx 
    WHERE innerx.a = #x.a  
);
GO 
SELECT *   
FROM #x  
WHERE EXISTS (      
    SELECT 1/0 --"Divide by zero error" obviously... but it doesn't matter! 
    FROM #x innerx 
    WHERE innerx.a = #x.a  
);
GO 
