USE Freddie
GO

DROP TABLE IF EXISTS dbo.srcEmployee
CREATE TABLE dbo.srcEmployee
(
	EmpID INT PRIMARY KEY IDENTITY(1,1)
	,EmpName VARCHAR(255)
	,Title VARCHAR(255)
)
GO

DROP TABLE IF EXISTS dbo.EmployeeDim
CREATE TABLE dbo.EmployeeDim
(
	EmployeeKey INT PRIMARY KEY IDENTITY(1,1)
	,EmployeeID INT 
	,EmployeeName VARCHAR(255)
	,Title VARCHAR(255)
	,EffectiveDate DATE
	,TerminateDate DATE
)
GO


INSERT INTO dbo.srcEmployee
(
	EmpName
   ,Title
)
VALUES
('Ken', 'Owner'),
('David', 'CTO'),
('Aaron', 'Consultant'),
('Spencer', 'Architect')
GO

SELECT *
FROM dbo.srcEmployee
GO

CREATE OR ALTER PROCEDURE dbo.EmployeeDimLoad
AS

SET NOCOUNT ON;

SET XACT_ABORT ON;

BEGIN TRANSACTION;

	DECLARE @UpdatedRecords TABLE
	(
		EmpID INT
	);

	-- mark any existing records terminatedate
	UPDATE d
	SET TerminateDate = DATEADD(DAY, -1, GETDATE())
	OUTPUT s.EmpID INTO @UpdatedRecords
	FROM dbo.EmployeeDim d
		INNER JOIN dbo.srcEmployee s
			ON s.EmpID = d.EmployeeID
	WHERE d.TerminateDate = '2199-12-31'
		AND (d.Title <> s.Title
			OR d.EmployeeName <> s.EmpName)
		

	
	-- insert new terminated records into the database
	INSERT INTO dbo.EmployeeDim
	(
		EmployeeID
	   ,EmployeeName
	   ,Title
	   ,EffectiveDate
	   ,TerminateDate
	)
	SELECT s.EmpID
		  ,s.EmpName
		  ,s.Title
		  ,'1900-01-01' AS EffectiveDate
		  ,'2199-12-31' AS TerminateDate
	FROM dbo.srcEmployee s
	WHERE NOT EXISTS (SELECT *
						FROM dbo.EmployeeDim d
						WHERE s.EmpID = d.EmployeeID)
	UNION 
	-- insert new values
	SELECT e.EmpID
		  ,e.EmpName
		  ,e.Title
		  ,GETDATE() AS EffectiveDate
		  ,'2199-12-31' AS TerminateDate
	FROM dbo.srcEmployee e
		INNER JOIN @UpdatedRecords u
			ON u.EmpID = e.EmpID;

COMMIT;
GO

EXEC dbo.EmployeeDimLoad
GO

SELECT *
FROM dbo.EmployeeDim
GO


UPDATE dbo.srcEmployee
SET Title = 'VP'
WHERE EmpName = 'Aaron'
GO

INSERT dbo.srcEmployee
(
	EmpName
   ,Title
)
VALUES
('Jeff', 'ML Consultant')
GO

SELECT *
FROM dbo.srcEmployee
GO

EXEC dbo.EmployeeDimLoad
GO

SELECT *
FROM dbo.EmployeeDim