/* 
Overview:
Using OUTPUT table to show rows affected 
*/ 
BEGIN 
    --drop temp tables if they exist 
    IF NOT OBJECT_ID('tempdb..#PretendBalances') IS NULL DROP TABLE #PretendBalances; 
    IF NOT OBJECT_ID('tempdb..#tobeupdated') IS NULL DROP TABLE #tobeupdated; 
 
    --create and populate a temp table 
    CREATE TABLE #PretendBalances (id INT IDENTITY(1,1) PRIMARY KEY, CustomerName NVARCHAR(50), Balance INT); 
    INSERT INTO #PretendBalances VALUES ('Darek', 200), ('Kara', 300), ('Kurtis', 500), ('Emily', 600); 
END 
 
--show data... should be 4 rows... 
SELECT * FROM #PretendBalances 
 
--OBJECTIVE: Update all balances by 1 where balance is <=300
--	showing balance before and after

--lots of ways to do this before... here is one way 
BEGIN TRAN 
    SELECT * 
	INTO #tobeupdated 
	FROM #PretendBalances 
	WHERE Balance <= 300;
    
	UPDATE #PretendBalances 
	SET Balance = Balance + 1 
	WHERE 
		id IN 
		(
			SELECT id 
			FROM #tobeupdated
		);
		 
    SELECT 
		#PretendBalances.id,
		#tobeupdated.CustomerName,
		#tobeupdated.Balance [Old Balance],
		#PretendBalances.Balance [New Balance] 
    FROM #PretendBalances  
    JOIN #tobeupdated 
        ON #tobeupdated.id = #PretendBalances.id;

ROLLBACK TRAN 

--much better way is just use OUTPUT 
BEGIN TRAN 
    UPDATE #PretendBalances 
	SET Balance = Balance + 1
	OUTPUT 
		deleted.id,
		deleted.CustomerName,
		deleted.Balance [Old Balance],
		inserted.Balance [New Balance] 
    WHERE Balance <= 300; 
ROLLBACK TRAN 
 
--if want to do extra querying with this data then add an "INTO" clause... 
BEGIN TRAN 
    DECLARE @BalanceUpdates TABLE (id INT, CustomerName NVARCHAR(50), [Old Balance] INT, [New Balance] INT);

    UPDATE #PretendBalances 
	SET Balance = Balance + 1  
    OUTPUT 
		deleted.id,
		deleted.CustomerName,
		deleted.Balance [Old Balance],
		inserted.Balance [New Balance] 
	INTO @BalanceUpdates 
    WHERE Balance <= 300; 
    
	SELECT * FROM @BalanceUpdates;
ROLLBACK TRAN 
 
--another interesting part of this are inserts to an identity column... 
INSERT INTO #PretendBalances  
OUTPUT inserted.* 
VALUES ('hi', 999), ('there', 888); 
 
--...and of course deleted... 
DELETE FROM #PretendBalances  
OUTPUT deleted.* 
WHERE Balance >=888 ;
