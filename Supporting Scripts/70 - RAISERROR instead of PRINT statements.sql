/*
Overview:
Demonstrates using RAISERROR to return information sooner

NOTE:
- I believe I have heard that RAISERROR might be slowly going away???
If this is the case I am not sure what the equivalent new way is to this
*/

SELECT 'first result';
PRINT 'hi';
WAITFOR DELAY '00:00:02';
SELECT 'second result';
 
 
SELECT 'first result';
RAISERROR('hi', 0, 1) WITH NOWAIT;
WAITFOR DELAY '00:00:02';
SELECT 'second result';
