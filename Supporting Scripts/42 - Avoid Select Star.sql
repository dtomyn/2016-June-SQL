/*
Overview:
Demonstrates issues with "SELECT *" and views
*/
USE AdventureWorks2014

SET NOCOUNT ON;
DBCC FREEPROCCACHE WITH NO_INFOMSGS;
GO

--compare execution plans between the following 2...

--this one requires a key lookup for the spatial location data
SELECT *
FROM Person.[Address] 
WHERE AddressLine1 LIKE '1% Napa%';

--this one though we are returning only the data we need... and did not need to go and get the rest of the data
SELECT 
	AddressID,
	AddressLine1,
	AddressLine2,
	City,
	StateProvinceID,
	PostalCode
FROM Person.[Address] 
WHERE 
	AddressLine1 LIKE '1% Napa%';




-- schema stability 
-- view does not reflect changed table

USE tempdb;
GO
IF NOT OBJECT_ID('tempdb.dbo.CommonEntity') IS NULL
	DROP TABLE dbo.CommonEntity;
GO

CREATE TABLE dbo.CommonEntity(FirstName VARCHAR(50), LastName VARCHAR(50));
GO

INSERT dbo.CommonEntity(FirstName,LastName) 
VALUES
	('Darek','Tomyn'),
	('Kara','Tomyn'),
	('Kurtis','Tomyn'),
	('Emily','Tomyn')
	;
GO

IF NOT OBJECT_ID('tempdb.dbo.v_CommonEntity') IS NULL
	DROP VIEW dbo.v_CommonEntity;
GO

CREATE VIEW dbo.v_CommonEntity
AS
  SELECT * FROM dbo.CommonEntity;
GO

SELECT * FROM dbo.CommonEntity
SELECT * FROM dbo.v_CommonEntity

ALTER TABLE dbo.CommonEntity ADD Surname VARCHAR(50);

UPDATE dbo.CommonEntity SET Surname = LastName;

-- view will not be updated to see these changes:
EXEC sys.sp_rename N'dbo.CommonEntity.LastName', N'MiddleInitial', N'COLUMN';

UPDATE dbo.CommonEntity 
SET MiddleInitial = 
	CASE FirstName 
		WHEN 'Darek' THEN 'E'
		WHEN 'Kara' THEN 'L'
		WHEN 'Kurtis' THEN 'E'
		WHEN 'Emily' THEN 'M'
	END
		;

-- view still shows wrong data
select * FROM dbo.CommonEntity;
SELECT * FROM dbo.v_CommonEntity;
GO

EXEC sys.sp_refreshview @viewname = N'dbo.v_CommonEntity';
GO

-- now view is correct
SELECT * FROM dbo.v_CommonEntity;
GO

DROP VIEW dbo.v_CommonEntity;
DROP TABLE dbo.CommonEntity;