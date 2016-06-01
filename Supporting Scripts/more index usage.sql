/*
Overview:
Demonstates...
- seeks
- index scan
- how 
*/
USE AdventureWorks2014;
GO
IF EXISTS(SELECT 1/0 FROM sys.indexes si WHERE si.name = 'ln' AND OBJECT_NAME(si.object_id) = 'Person')
	DROP INDEX Person.Person.ln; 

SELECT FirstName, LastName
FROM Person.Person
WHERE LastName LIKE N'S%';
--will be an index seek as it will use IX_Person_LastName_FirstName_MiddleName

SELECT FirstName, LastName
FROM Person.Person
WHERE LastName LIKE N'%S%';
--will be an index scan

CREATE INDEX ln ON Person.Person(LastName) INCLUDE(FirstName);

--many people will say that it will "scan the entire table"... well... not really...
SELECT FirstName, LastName
FROM Person.Person WITH (INDEX (PK_Person_BusinessEntityID))
WHERE LastName LIKE N'%S%';

--this can still use the "skinny index"... scans the whole thing, but realizes it can use the smaller one!
SELECT FirstName, LastName
FROM Person.Person WITH (INDEX (ln))
WHERE LastName LIKE N'%S%';

--so... running this without the hint what will it do?
SELECT FirstName, LastName
FROM Person.Person 
WHERE LastName LIKE N'%S%';
--...will use the "ln" index

--same thing goes with COUNT(*) by the way...
SELECT COUNT(*)
FROM Person.Person
WHERE LastName LIKE N'%S%';

--...and if just a big count without the where...
SELECT COUNT(*)
FROM Person.Person;
--uses the SMALLEST index... AK_Person_rowguid
