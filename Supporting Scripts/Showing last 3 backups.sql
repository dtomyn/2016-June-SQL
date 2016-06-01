--using max and group by
SELECT 
	sd.name,
	MAX(bs.backup_finish_date)
FROM sys.databases sd
LEFT JOIN msdb.dbo.backupset bs
	ON bs.database_name = sd.name
GROUP BY
	sd.name;

--... but VERY LIMITING!!! that is, what if want more columns from backupset?
--or, what if want last 3 backups?

SET STATISTICS IO ON
SET STATISTICS TIME ON

--old school correlated subquery using CROSS APPLY...
SELECT 
	sd.name,
	BackupList.backup_finish_date
FROM sys.databases sd
CROSS APPLY (
	SELECT TOP 3 *
	FROM msdb.dbo.backupset bs
	WHERE 
		bs.database_name = sd.name
	ORDER BY
		bs.backup_finish_date
) BackupList
ORDER BY
	sd.name,
	BackupList.backup_finish_date;

--using correlated subquery
SELECT 
	sd.name,
	BackupList.backup_finish_date
FROM sys.databases sd
LEFT JOIN 
	(
		SELECT 
			bs.*,
			ROW_NUMBER() OVER(
				PARTITION BY bs.database_name
				ORDER BY bs.backup_finish_date DESC) RowNumber
		FROM msdb.dbo.backupset bs
	) BackupList
	ON BackupList.database_name = sd.name
	AND BackupList.RowNumber <= 3
ORDER BY
	sd.name,
	BackupList.backup_finish_date;


--Using common table expression
WITH LastBackupCTE
AS
(
	SELECT 
		bs.*,
		ROW_NUMBER() OVER(
			PARTITION BY bs.database_name
			ORDER BY bs.backup_finish_date DESC) RowNumber
	FROM msdb.dbo.backupset bs
)
SELECT 
	sd.name,
	LastBackupCTE.backup_finish_date
FROM sys.databases sd
LEFT JOIN LastBackupCTE
	ON LastBackupCTE.database_name = sd.name
	AND LastBackupCTE.RowNumber <= 1
ORDER BY
	sd.name
	, LastBackupCTE.backup_finish_date;


