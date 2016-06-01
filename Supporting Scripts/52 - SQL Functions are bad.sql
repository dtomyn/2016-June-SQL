/*
Overview:
Demonstrates issues with functions

NOTE: need to use SQL Sentry Plan Explorer on this one
*/
SET NOCOUNT ON

IF NOT OBJECT_ID('UglyFormat') IS NULL  
    DROP FUNCTION UglyFormat;
GO 
CREATE FUNCTION dbo.UglyFormat (@d DATETIME) 
RETURNS VARCHAR(20) 
BEGIN 
    --some really really bad data access code 
    DECLARE @x TABLE (somedate DATETIME2);
    INSERT INTO @x  
    SELECT s1.create_date  
    FROM sys.objects s1 
	CROSS JOIN sys.objects s2 
	--CROSS JOIN sys.objects s3 
	--CROSS JOIN sys.objects s4 
 
    RETURN  
    ( 
        SELECT DATENAME(MONTH, @d) + CONVERT(VARCHAR(2), DATEPART(DAY, @d)) + CONVERT(CHAR(4), DATEPART(YEAR, @d)) 
    ) 
END 
GO 
IF NOT OBJECT_ID('PrettyFormat') IS NULL  
    DROP FUNCTION PrettyFormat;
GO 
CREATE FUNCTION dbo.PrettyFormat (@d DATETIME) 
RETURNS VARCHAR(20) 
BEGIN 
    RETURN  
    ( 
        SELECT DATENAME(MONTH, @d) + CONVERT(VARCHAR(2), DATEPART(DAY, @d)) + CONVERT(CHAR(4), DATEPART(YEAR, @d)) 
    ) 
END 
GO 
 
SET STATISTICS IO ON 
SET STATISTICS TIME ON
SELECT TOP 50 
	dbo.PrettyFormat(SO.create_date) 
FROM sys.objects AS SO;
 
SELECT TOP 50 
	dbo.UglyFormat(SO.create_date) 
FROM sys.objects AS SO;
 
SELECT TOP 50 
	DATENAME(MONTH, SO.create_date) + CONVERT(VARCHAR(2), DATEPART(DAY, SO.create_date)) + CONVERT(CHAR(4), DATEPART(YEAR, SO.create_date)) 
FROM sys.objects AS SO;

--interestingly enough... estimate plan will give you a better view then the actual :(