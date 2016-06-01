SET NOCOUNT ON
GO
USE MASTER
GO
SELECT 'Creating database...'
--drop database if it exists and then shrink it
IF DB_ID('AppPracticeDemo_ShrinkFrag') IS NOT NULL 
	DROP DATABASE AppPracticeDemo_ShrinkFrag
CREATE DATABASE AppPracticeDemo_ShrinkFrag
GO

USE AppPracticeDemo_ShrinkFrag
GO

--Create a table... will be at start of file. This will be dropped later
SELECT 'Creating table WillBeDroppedLater and inserting lots of data into it...'
CREATE TABLE WillBeDroppedLater (
	c1 INT IDENTITY,
	c2 CHAR (8000) DEFAULT 'stuff')
GO

--Fill up the table
INSERT INTO WillBeDroppedLater DEFAULT VALUES
GO 1280

--Create table that will stick around
SELECT 'Creating table WillStayAround and inserting lots of data into it...'
CREATE TABLE WillStayAround (
	c1 INT IDENTITY,
	c2 CHAR (8000) DEFAULT 'stuff')
CREATE CLUSTERED INDEX idx_WillStayAround
	ON WillStayAround (c1)
GO

INSERT INTO WillStayAround DEFAULT VALUES
GO 1280

--Check the fragmentation of table that is staying around... should be really low
SELECT 'Checking fragmentation of table WillStayAround...'
SELECT
	[avg_fragmentation_in_percent]
FROM sys.dm_db_index_physical_stats (
	DB_ID ('AppPracticeDemo_ShrinkFrag'),
	OBJECT_ID ('WillStayAround'),
	1,
	NULL,
	'LIMITED')
GO

-- Drop the 1st table, creating a bunch of free space at front of file
SELECT 'Dropped table WillBeDroppedLater...'
DROP TABLE WillBeDroppedLater
GO

-- Shrink the database
SELECT 'Shrinking database...'
DBCC SHRINKDATABASE ('AppPracticeDemo_ShrinkFrag')
GO

-- Check the index fragmentation again
SELECT 'Checking fragmentation of table WillStayAround...'
SELECT
	[avg_fragmentation_in_percent]
FROM sys.dm_db_index_physical_stats (
	DB_ID ('AppPracticeDemo_ShrinkFrag'),
	OBJECT_ID ('WillStayAround'),
	1,
	NULL,
	'LIMITED')
GO
