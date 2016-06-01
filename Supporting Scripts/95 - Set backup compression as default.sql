/*
Overview:
Shows how to set via T-SQL backup compression and to query it afterward
*/

EXEC sp_configure 'backup compression default', 1;

RECONFIGURE WITH OVERRIDE;

SELECT 
	value  
FROM sys.configurations  
WHERE 
	name = 'backup compression default'; 
GO 
