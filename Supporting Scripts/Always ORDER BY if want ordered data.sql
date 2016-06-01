/*
Overview:
Demonstrates how to never assume how SQL Server is going to return back data.
That is, one does NOT by default get data returned back in order it was inserted
*/
IF NOT OBJECT_ID('dbo.TomynFamily') IS NULL
	DROP TABLE dbo.TomynFamily;
GO

CREATE TABLE dbo.TomynFamily
(
  PersonID INT IDENTITY(1,1) PRIMARY KEY CLUSTERED, 
  Name SYSNAME
);
INSERT dbo.TomynFamily(Name) 
VALUES
	('Kurtis'),
	('Darek'),
	('Emily'),
	('Kara');
 
SELECT 
	Name 
FROM dbo.TomynFamily; -- clustered index scan, ordered [Kurtis, Darek, Emily, Kara]
 
CREATE UNIQUE INDEX pn ON dbo.TomynFamily(Name);
 
SELECT 
	Name 
FROM dbo.TomynFamily; -- non-clustered index scan, ordered [Darek, Emily, Kara, Kurtis]

--even better yet, sort it if that's what you want!!
SELECT 
	Name 
FROM dbo.TomynFamily 
ORDER BY 
	Name;

--NOTE: NEVER EVER RELY on a built-in sort
--ALSO, NEVER use the old "trick" of ORDER BY and TOP 100 PERCENT in a view... it was always
--unsupported and now has been optimized away see: https://blogs.msdn.microsoft.com/queryoptteam/2006/03/24/top-100-percent-order-by-considered-harmful/
