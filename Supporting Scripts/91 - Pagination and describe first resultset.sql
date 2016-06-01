/*
Overview:
Overall purpose is showing describing proceduer "sp_describe_first_result_set"
HOWEVER, I also took opportunity of showing new paging mechanisms in a proc
*/
IF NOT OBJECT_ID('dbo.ucp_s_sysobjects_ByPage') IS NULL
	DROP PROCEDURE dbo.ucp_s_sysobjects_ByPage;
GO

CREATE PROCEDURE dbo.ucp_s_sysobjects_ByPage
( 
	@PageNumber INT = 1,              -- Default to first page 
	@RowsPerPage INT = 10             -- Default to 10 rows per page 
) 
AS 
BEGIN 
  DECLARE @RowsToSkip INT = @RowsPerPage * (@PageNumber - 1); 
  SELECT 
	so.[object_id],
	so.[name]
  FROM sys.objects AS so
  ORDER BY 
	so.[object_id],
	so.[name]
  OFFSET @RowsToSkip ROWS
  FETCH NEXT @RowsPerPage ROWS ONLY; 
END; 
GO

EXEC ucp_s_sysobjects_ByPage 2, 4
EXEC ucp_s_sysobjects_ByPage 5, 8

EXEC dbo.sp_describe_first_result_set  N'EXEC dbo.ucp_s_sysobjects_ByPage', NULL, 0 
EXEC dbo.sp_describe_first_result_set  N'EXEC dbo.ucp_s_sysobjects_ByPage', NULL, 1
EXEC dbo.sp_describe_first_result_set  N'EXEC dbo.ucp_s_sysobjects_ByPage', NULL, 2 


