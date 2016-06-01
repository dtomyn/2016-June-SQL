/*
Overview:
Very SIMPLISTIC formatting demonstrating to try to get point across
*/
USE AdventureWorks2014;
GO

--before...
declare @name varchar(10) = 'S' 
select p.LastName , HumanResources.Employee.BirthDate
,case when month(HumanResources.Employee.BirthDate) BETWEEN 4 AND 5 THEN 'Spring Baby'
		when month(HumanResources.Employee.BirthDate) BETWEEN 6 AND 8 THEN 'Summer Baby'
		when month(HumanResources.Employee.BirthDate) BETWEEN 9 AND 10 THEN 'Fall Baby'
		else 'Winter Baby'
	END AS [Type of Baby],HumanResources.Employee.Gender, HumanResources.Employee.MaritalStatus 
from HumanResources.Employee join HumanResources.EmployeeDepartmentHistory eh on eh.BusinessEntityID = HumanResources.Employee.BusinessEntityID join HumanResources.EmployeePayHistory eph
	on eph.BusinessEntityID = HumanResources.Employee.BusinessEntityID inner join Person.Person p on p.BusinessEntityID = HumanResources.Employee.BusinessEntityID and CurrentFlag = 1
	where p.LastName like @name + '%'
		order by 1, 2;

GO

--after...
--just with simplistic formatting realized that joining to 2 tables 
--that don't need to be joined to!
--Some things I DID do:
-- CAPITALIZE all keywords
-- commas at the end... notice how it works really nice for CASE statements
-- prefix columns with where they came from... otherwise can be difficult to figure out where
-- removed unnecessary "INNER" for join
-- JOINs are all on a new line
-- join clauses on new lines
-- predicates (i.e. where criteria) are on new lines
DECLARE @LastName VARCHAR(10) = 'S'
SELECT
	p.LastName, 
	HumanResources.Employee.BirthDate, 
	CASE 
		WHEN MONTH(HumanResources.Employee.BirthDate) BETWEEN 4 AND 5 THEN 'Spring Baby'
		WHEN MONTH(HumanResources.Employee.BirthDate) BETWEEN 6 AND 8 THEN 'Summer Baby'
		WHEN MONTH(HumanResources.Employee.BirthDate) BETWEEN 9 AND 10 THEN 'Fall Baby'
		ELSE 'Winter Baby'
	END AS [Type of Baby],
	HumanResources.Employee.Gender,
	HumanResources.Employee.MaritalStatus 
FROM HumanResources.Employee 
--JOIN HumanResources.EmployeeDepartmentHistory AS eh 
--	ON eh.BusinessEntityID = HumanResources.Employee.BusinessEntityID 
--JOIN HumanResources.EmployeePayHistory AS eph
--	ON eph.BusinessEntityID = HumanResources.Employee.BusinessEntityID 
JOIN Person.Person AS p 
	ON p.BusinessEntityID = HumanResources.Employee.BusinessEntityID 
WHERE 
	p.LastName LIKE @LastName + '%'
	AND HumanResources.Employee.CurrentFlag = 1
ORDER BY 
	p.LastName, 
	HumanResources.Employee.BirthDate;

