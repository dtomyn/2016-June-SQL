/*
Overview:
Demonstrates the importance of checking errors in procs
*/
IF NOT OBJECT_ID('ProcThatHasAnErrorWithinIt') IS NULL 
    DROP PROCEDURE ProcThatHasAnErrorWithinIt;
GO 
CREATE PROCEDURE dbo.ProcThatHasAnErrorWithinIt 
AS 
BEGIN 
	SET NOCOUNT ON
    --since the next statement fails we should stop! 
    SELECT 1/0;
    --...but it WON'T stop... it will continue on its merry way 
    SELECT * FROM sysusers;
    SELECT * FROM sysobjects;
	SET NOCOUNT OFF
END 
GO 
EXEC ProcThatHasAnErrorWithinIt;
GO 
 
IF NOT OBJECT_ID('ProcThatHasAnErrorWithinIt2') IS NULL 
    DROP PROCEDURE ProcThatHasAnErrorWithinIt2;
GO 
CREATE PROCEDURE dbo.ProcThatHasAnErrorWithinIt2 
AS 
BEGIN 
	SET NOCOUNT ON
    SELECT 1/0;
    IF @@ERROR > 0 
        RETURN;
    SELECT * FROM sysusers;
    IF @@ERROR > 0 
        RETURN;
    SELECT * FROM sysobjects;
    IF @@ERROR > 0 
        RETURN;
	SET NOCOUNT OFF
END 
GO 
EXEC ProcThatHasAnErrorWithinIt2;
GO 

IF NOT OBJECT_ID('ProcThatHasAnErrorWithinIt2WithTryCatch') IS NULL 
    DROP PROCEDURE ProcThatHasAnErrorWithinIt2WithTryCatch;
GO 
CREATE PROCEDURE dbo.ProcThatHasAnErrorWithinIt2WithTryCatch
AS 
BEGIN 
	SET NOCOUNT ON
	BEGIN TRY
		SELECT 1/0;
		SELECT * FROM sysusers;
		SELECT * FROM sysobjects;
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END 
GO 
EXEC ProcThatHasAnErrorWithinIt2WithTryCatch;
GO 
 

IF NOT OBJECT_ID('ProcThatHasAnErrorWithinIt3') IS NULL 
    DROP PROCEDURE ProcThatHasAnErrorWithinIt3;
GO 
CREATE PROCEDURE dbo.ProcThatHasAnErrorWithinIt3 
@validateMe INT 
AS 
BEGIN 
	SET NOCOUNT ON
    IF @validateMe < 0 
        RAISERROR('please provide a non-0 number', 16, 1);
    SELECT * FROM sysusers;
END 
GO 
EXEC ProcThatHasAnErrorWithinIt3 -10;
 
IF NOT OBJECT_ID('ProcThatHasAnErrorWithinIt4') IS NULL 
    DROP PROCEDURE ProcThatHasAnErrorWithinIt4;
GO 
CREATE PROCEDURE dbo.ProcThatHasAnErrorWithinIt4 
@validateMe INT 
AS 
BEGIN 
    IF @validateMe < 0 
    BEGIN 
        RAISERROR('please provide a non-0 number', 16, 1);
        RETURN;
    END 
    SELECT * FROM sysusers;
END 
GO 
EXEC ProcThatHasAnErrorWithinIt4 -10;


IF NOT OBJECT_ID('ProcThatHasAnErrorWithinIt4TryCatch') IS NULL 
    DROP PROCEDURE ProcThatHasAnErrorWithinIt4TryCatch;
GO 
CREATE PROCEDURE dbo.ProcThatHasAnErrorWithinIt4TryCatch 
@validateMe INT 
AS 
BEGIN 
	BEGIN TRY
		IF @validateMe < 0 
		BEGIN 
			RAISERROR('please provide a non-0 number', 16, 1);
		END 
	
		SELECT * FROM sysusers;
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END 
GO 
EXEC ProcThatHasAnErrorWithinIt4TryCatch -10;
