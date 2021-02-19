USE Freddie
GO

-- create some tables
DROP TABLE IF EXISTS dbo.Sales
CREATE TABLE dbo.Sales
(
	SaleID INT IDENTITY(1,1)
	,SaleDate DATETIME
	,CustomerID INT
	,ItemID INT
	,DiscountID1 INT
	,DiscountID2 INT
	,DiscountID3 INT
	,SalePrice MONEY
)
GO

DROP TABLE IF EXISTS dbo.Discounts
CREATE TABLE dbo.Discounts
(
	DiscountID INT
	,DiscountName VARCHAR(50)
)
GO

DROP TABLE IF EXISTS dbo.Customer
CREATE TABLE dbo.Customer
(
	CustomerID INT 
	,CustomerName VARCHAR(50)
)
GO

DROP TABLE IF EXISTS dbo.Item
CREATE TABLE dbo.Item 
(
	ItemID INT
	,ItemName VARCHAR(50)
)
GO

-- load some data
INSERT INTO dbo.Customer
(
	CustomerID
   ,CustomerName
)
VALUES
(1, 'Bob'),
(2, 'Steve'),
(3, 'Mary')
GO

INSERT INTO dbo.Item
(
	ItemID
   ,ItemName
)
VALUES
(1, 'Large Coat'),
(2, 'Gloves'),
(3, 'Hat'),
(4, 'Shoes'),
(5, 'Pants')
GO

INSERT INTO dbo.Discounts
(
	DiscountID
   ,DiscountName
)
VALUES
(1, 'Polar Vortex Special'),
(2, '10% off Coupon'),
(3, '20% off Coupon')
GO

INSERT INTO dbo.Sales
(
	SaleDate
   ,CustomerID
   ,ItemID
   ,DiscountID1
   ,DiscountID2
   ,DiscountID3
   ,SalePrice
)
VALUES
('2019-01-29', 1, 4, NULL, NULL, NULL, 50),
('2019-01-29', 2, 1, 1, 2, NULL, 70),
('2019-01-30', 3, 2, 1, NULL, NULL, 10)
GO

--- create the model
DROP TABLE IF EXISTS dbo.SalesFact
CREATE TABLE dbo.SalesFact
(
	SaleID INT
	,SaleDateKey INT
	,CustomerKey INT
	,ItemKey INT
	,DiscountBridgeKey INT	
	,SalePrice MONEY
)
GO

DROP TABLE IF EXISTS dbo.CustomerDim
CREATE TABLE dbo.CustomerDim
(
	CustomerKey INT IDENTITY(1,1)
	,CustomerID INT 
	,CustomerName VARCHAR(50)
)
GO

DROP TABLE IF EXISTS dbo.ItemDim
CREATE TABLE dbo.ItemDim
(
	ItemKey INT IDENTITY(1,1)
	,ItemID INT
	,ItemName VARCHAR(50)
)
GO

DROP TABLE IF EXISTS dbo.DiscountBridge
CREATE TABLE dbo.DiscountBridge
(
	DiscountBridgeKey INT
	,DiscountKey INT
)
GO

DROP TABLE IF EXISTS dbo.DiscountDim
CREATE TABLE dbo.DiscountDim
(
	DiscountKey INT IDENTITY(1,1)
	,DiscountID INT 
	,DiscountName VARCHAR(50)
)
GO

DROP TABLE IF EXISTS dbo.DiscountBridgeGroup
CREATE TABLE dbo.DiscountBridgeGroup
(
	DiscountBridgeKey INT IDENTITY(1,1),
	DiscountString VARCHAR(1000)
)
GO

-- write the ETL
DROP PROCEDURE IF EXISTS dbo.CustomerDimLoad
GO

CREATE PROCEDURE dbo.CustomerDimLoad
AS
	
	-- update and existing customers (type 1)
	UPDATE d 
	SET CustomerName = c.CustomerName
	FROM dbo.CustomerDim d
		INNER JOIN dbo.Customer c
			ON c.CustomerID = d.CustomerID
	WHERE c.CustomerName <> d.CustomerName -- only update if it changed

	INSERT INTO dbo.CustomerDim
	(
		CustomerID
	   ,CustomerName
	)
	SELECT CustomerID
		,CustomerName
	FROM dbo.Customer c
	WHERE NOT EXISTS (SELECT *
						FROM dbo.CustomerDim d
						WHERE c.CustomerID = d.CustomerID)

GO

DROP PROCEDURE IF EXISTS dbo.ItemDimLoad
GO


CREATE PROCEDURE dbo.ItemDimLoad
AS
	
	-- update and existing customers (type 1)
	UPDATE d 
	SET ItemName = c.ItemName
	FROM dbo.ItemDim d
		INNER JOIN dbo.Item c
			ON c.ItemID = d.ItemID
	WHERE c.ItemName <> d.ItemName -- only update if it changed

	INSERT INTO dbo.ItemDim
	(
		ItemID
	   ,ItemName
	)
	SELECT ItemID
	   ,ItemName
	FROM dbo.Item c
	WHERE NOT EXISTS (SELECT *
						FROM dbo.ItemDim d
						WHERE c.ItemID = d.ItemID)

GO

DROP PROCEDURE IF EXISTS dbo.DiscountDimLoad
GO

CREATE PROCEDURE dbo.DiscountDimLoad
AS

	UPDATE d
	SET DiscountName = s.DiscountName
	FROM dbo.DiscountDim d
		INNER JOIN dbo.Discounts s
			ON s.DiscountID = d.DiscountID
	WHERE d.DiscountName <> s.DiscountName
	
	INSERT INTO dbo.DiscountDim
	(
		DiscountID
	   ,DiscountName
	)
	SELECT DiscountID
		,DiscountName
	FROM dbo.Discounts d
	WHERE NOT EXISTS (SELECT *
						FROM dbo.DiscountDim dd
						WHERE dd.DiscountID = d.DiscountID)

GO

DROP PROCEDURE IF EXISTS dbo.DiscountBridgeLoad
GO

CREATE PROCEDURE dbo.DiscountBridgeLoad
AS
	drop TABLE IF EXISTS #stage
	SELECT SaleID, STRING_AGG(unpvt.DiscountID, ',') AS DiscountString
	INTO #stage
	FROM dbo.Sales
	UNPIVOT
	(DiscountID FOR DiscountNumber IN
		(DiscountID1, DiscountID2, DiscountID3)
	) AS unpvt
	GROUP BY unpvt.SaleID
	
	-- insert new records into the bridge group
	INSERT INTO dbo.DiscountBridgeGroup
	(
		DiscountString
	)
	SELECT DISTINCT DiscountString
	FROM #stage s
	WHERE NOT EXISTS (SELECT *
						FROM dbo.DiscountBridgeGroup g
						WHERE g.DiscountString = s.DiscountString)

	INSERT INTO dbo.DiscountBridge
	(
		DiscountBridgeKey
	   ,DiscountKey
	)
	SELECT g.DiscountBridgeKey
		,d.DiscountKey
	FROM dbo.Sales 
	UNPIVOT
	(DiscountID FOR DiscountNumber IN
		(DiscountID1, DiscountID2, DiscountID3)
	) AS unpvt
	INNER JOIN dbo.DiscountDim d
		ON d.DiscountID = unpvt.DiscountID
	INNER JOIN #stage s
		ON s.SaleID = unpvt.SaleID
	INNER JOIN dbo.DiscountBridgeGroup g
		ON g.DiscountString = s.DiscountString
	WHERE NOT EXISTS (SELECT *
						FROM dbo.DiscountBridge db
						WHERE db.DiscountBridgeKey = g.DiscountBridgeKey
							AND db.DiscountKey = d.DiscountKey)

GO

DROP PROCEDURE IF EXISTS dbo.SalesFactLoad
GO

CREATE PROCEDURE dbo.SalesFactLoad
AS

	drop TABLE IF EXISTS #stage
	SELECT SaleID, STRING_AGG(unpvt.DiscountID, ',') AS DiscountString
	INTO #stage
	FROM dbo.Sales
	UNPIVOT
	(DiscountID FOR DiscountNumber IN
		(DiscountID1, DiscountID2, DiscountID3)
	) AS unpvt
	GROUP BY unpvt.SaleID
	

	TRUNCATE TABLE dbo.SalesFact

	INSERT INTO dbo.SalesFact
	(
		SaleID
	   ,SaleDateKey
	   ,CustomerKey
	   ,ItemKey
	   ,DiscountBridgeKey
	   ,SalePrice
	)
	SELECT s.SaleID
		,YEAR(s.SaleDate) * 10000 + MONTH(s.SaleDate) * 100 + DAY(s.SaleDate)
		,ISNULL(c.CustomerKey, -1)
		,ISNULL(i.ItemKey, -1)
		,ISNULL(dbg.DiscountBridgeKey, -1)
		,s.SalePrice
	FROM dbo.Sales s
		LEFT OUTER JOIN dbo.CustomerDim c
			ON c.CustomerID = s.CustomerID
		LEFT OUTER JOIN dbo.ItemDim i
			ON i.ItemID = s.ItemID
		LEFT OUTER JOIN #stage stg
			ON stg.SaleID = s.SaleID
		LEFT OUTER JOIN dbo.DiscountBridgeGroup dbg
			ON dbg.DiscountString = stg.DiscountString

GO


EXEC dbo.CustomerDimLoad
EXEC dbo.ItemDimLoad
EXEC dbo.DiscountDimLoad
EXEC dbo.DiscountBridgeLoad
EXEC dbo.SalesFactLoad
GO

SELECT *
FROM dbo.CustomerDim

SELECT *
FROM dbo.ItemDim

SELECT *
FROM dbo.DiscountDim

SELECT *
FROM dbo.DiscountBridge

SELECT *
FROM dbo.SalesFact

SELECT *
FROM dbo.SalesFact f
	INNER JOIN dbo.DiscountBridge b
		ON b.DiscountBridgeKey = f.DiscountBridgeKey
	INNER JOIN dbo.DiscountDim d
		ON d.DiscountKey = b.DiscountKey
WHERE d.DiscountName = 'Polar Vortex Special'
		