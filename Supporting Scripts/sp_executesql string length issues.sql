/*
For search queries, to prevent bad plans, one approach is to use sp_executesql
This example is going to show how string lengths can get in your way and to prevent issues
*/
SET NOCOUNT ON
 
--first... create temp table going to be inserting into using sp_executesql
IF NOT OBJECT_ID('tempdb..#t') IS NULL
       DROP TABLE #t
CREATE TABLE #t
(SomeColumn NVARCHAR(MAX))
 
--next... just show how can insert into table large content
INSERT INTO #t
SELECT REPLICATE('i', 8001)
 
--display lengths... len shows what people usually expect
SELECT LEN(SomeColumn) FROM #t
--while the DATALENGTH shows the actual storage of the string (since nvarchar)
SELECT DATALENGTH(SomeColumn) FROM #t
 
--clear up temp table
TRUNCATE TABLE #t
GO
 
--next... build up a string and use sp_executesql to execute
DECLARE @Sql NVARCHAR(MAX)
 
SET @Sql = '
INSERT INTO #t
SELECT ''' + REPLICATE('i', 7001) + ''''
EXECUTE sp_executesql @Sql
 
--display lengths
SELECT LEN(SomeColumn) FROM #t
TRUNCATE TABLE #t
GO
 
--still all is good... lets max out thinking that we might have a "8000" limit (since that is a "normal"
--max string length...
DECLARE @Sql NVARCHAR(MAX)
 
SET @Sql = '
INSERT INTO #t
SELECT ''' + REPLICATE('i', 8000-27) + ''''
EXECUTE sp_executesql @Sql
 
--display lengths
SELECT LEN(SomeColumn) FROM #t
TRUNCATE TABLE #t
go
 
--why the 27? well... I am predicting how "8000" is going to come into play here
 
--the first part of the sql is 26 characters in length... see below...
--so, this is why 27 since I want to show that something that does not exceed 8000 will work
--just fine
select len('
INSERT INTO #t
SELECT ''')
go
 
--now... run the below... guess what is going to happen
DECLARE @Sql NVARCHAR(MAX)
 
SET @Sql = '
INSERT INTO #t
SELECT ''' + REPLICATE('i', 8000-26) + ''''
EXECUTE sp_executesql @Sql
 
--display lengths
SELECT LEN(SomeColumn) FROM #t
SELECT DATALENGTH(SomeColumn) FROM #t
TRUNCATE TABLE #t
GO
 
--...why did it error? limitation of sp_executesql perhaps??
 
--this is where I have seen many start to alias tables, remove "INNER" and "dbo", etc
--all in an effort to cutdown the string
--but let's see if there is a better answer and in so doing understand
--what is going on here...
DECLARE @Sql NVARCHAR(MAX)
 
SET @Sql = N'
INSERT INTO #t
SELECT ''' + REPLICATE('i', 8000-26) + ''''
EXECUTE sp_executesql @Sql
 
--display lengths
SELECT LEN(SomeColumn) FROM #t
SELECT DATALENGTH(SomeColumn) FROM #t
TRUNCATE TABLE #t
GO
 
--still fails... so not because of string conversion... or is it?
DECLARE @Sql NVARCHAR(MAX)
 
SET @Sql = CAST('' as NVARCHAR(MAX))
+ '
INSERT INTO #t
SELECT ''' + REPLICATE('i', 8000-26) + ''''
EXECUTE sp_executesql @Sql
 
--display lengths
SELECT LEN(SomeColumn) FROM #t
SELECT DATALENGTH(SomeColumn) FROM #t
TRUNCATE TABLE #t
GO
 
--yeah... it IS because of this! that is, SQL Server will evaluate the right hand side first
--and since doesn't know how large it is going to be it default it to 8000 characters
--so... first thing to do before concatenating is to encourage sql server to be NVARCHAR(MAX)
 
--however, in practice usually it is simply best to do something like this...
DECLARE @Sql NVARCHAR(MAX)
 
SET @Sql =
'
INSERT INTO #t '
SET @Sql = @Sql
+ 'SELECT '''
--some comment about the select statement here...
SET @Sql = @Sql
+ REPLICATE('i', 8000-26) + ''''
--some comment about a table being joined to here...
--or a where statement, etc. This helps bring up the syntax
EXECUTE sp_executesql @Sql
 
--display lengths
SELECT LEN(SomeColumn) FROM #t
SELECT DATALENGTH(SomeColumn) FROM #t
select SomeColumn from #t
TRUNCATE TABLE #t
GO
 
--...whoa... what just happened there?
 
select len('iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii')
--i see... it only actually inserted a 4000 long string??
 
--try to do something smaller...
DECLARE @Sql NVARCHAR(MAX)
 
SET @Sql =
'
INSERT INTO #t '
SET @Sql = @Sql
+ 'SELECT '''
--some comment about the select statement here...
SET @Sql = @Sql
+ REPLICATE('i', 3000) + ''''
--some comment about a table being joined to here...
--or a where statement, etc. This helps bring up the syntax
EXECUTE sp_executesql @Sql
 
--display lengths
SELECT LEN(SomeColumn) FROM #t
SELECT DATALENGTH(SomeColumn) FROM #t
select SomeColumn from #t
TRUNCATE TABLE #t
GO
 
 
--try to do something smaller...
DECLARE @Sql NVARCHAR(MAX)
 
SET @Sql =
'
INSERT INTO #t '
SET @Sql = @Sql
+ 'SELECT '''
--some comment about the select statement here...
SET @Sql = @Sql + CAST('' AS NVARCHAR(MAX))
+ REPLICATE('i', 8000-26) + ''''
--some comment about a table being joined to here...
--or a where statement, etc. This helps bring up the syntax
EXECUTE sp_executesql @Sql
 
--display lengths
SELECT LEN(SomeColumn) FROM #t
SELECT DATALENGTH(SomeColumn) FROM #t
select SomeColumn from #t
TRUNCATE TABLE #t
GO
 
DECLARE @Sql NVARCHAR(MAX)
 
SET @Sql =
'
INSERT INTO #t '
SET @Sql = @Sql
+ 'SELECT '''
--some comment about the select statement here...
SET @Sql = @Sql + CAST('' AS NVARCHAR(MAX))
+ REPLICATE('i', 4000)
+ REPLICATE('i', 4000)
+ ''''
--some comment about a table being joined to here...
--or a where statement, etc. This helps bring up the syntax
EXECUTE sp_executesql @Sql
 
--display lengths
SELECT LEN(SomeColumn) FROM #t
SELECT DATALENGTH(SomeColumn) FROM #t
select SomeColumn from #t
TRUNCATE TABLE #t
GO
 
DECLARE @Sql NVARCHAR(MAX)
 
SET @Sql =
'
INSERT INTO #t '
SET @Sql = @Sql
+ 'SELECT '''
--some comment about the select statement here...
SET @Sql = @Sql + CAST('' AS NVARCHAR(MAX))
+ REPLICATE('i', 4000)
+ REPLICATE('i', 4000)
+ REPLICATE('i', 4000)
+ ''''
--some comment about a table being joined to here...
--or a where statement, etc. This helps bring up the syntax
EXECUTE sp_executesql @Sql
 
--display lengths
SELECT LEN(SomeColumn) FROM #t
SELECT DATALENGTH(SomeColumn) FROM #t
select SomeColumn from #t
TRUNCATE TABLE #t
GO
 