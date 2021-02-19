-- Create a Database Master Key.
CREATE MASTER KEY;

GO

-- Create a database scoped credential
CREATE DATABASE SCOPED CREDENTIAL ADLSG1Credential
WITH
    IDENTITY = '7ad35902-e4a4-485b-9062-d4ad98752f5d@https://login.microsoftonline.com/c57f7ac8-25a9-4286-a01e-31745bf28d50/oauth2/token',
    SECRET = 'BDDiPe2cq9YLpCFGPYNiukvU6YZDPubL1h3Bl6XpUJA='
;
GO


-- create an external data source to Azure Data Lake
CREATE EXTERNAL DATA SOURCE AzureDataLakeStorageGen1
WITH (
    TYPE = HADOOP,
    LOCATION = 'adl://tdilendingclubdemo.azuredatalakestore.net',
    CREDENTIAL = ADLSG1Credential
);

GO


-- create an external file format so the external table knows how to interpret the data
CREATE EXTERNAL FILE FORMAT ParquetFormat
WITH (
	FORMAT_TYPE = PARQUET,
	DATA_COMPRESSION = 'org.apache.hadoop.io.compress.SnappyCodec'
)
GO


-- D: Create an External Table
-- LOCATION: Folder under the Data Lake Storage Gen1 root folder.
-- DATA_SOURCE: Specifies which Data Source Object to use.
-- FILE_FORMAT: Specifies which File Format Object to use
-- REJECT_TYPE: Specifies how you want to deal with rejected rows. Either Value or percentage of the total
-- REJECT_VALUE: Sets the Reject value based on the reject type.

IF EXISTS (SELECT * FROM sys.tables WHERE name = 'LoanHistoryExt' AND is_external = 1)
	DROP EXTERNAL TABLE dbo.LoanHistoryExt;

-- DimProduct
CREATE EXTERNAL TABLE [dbo].LoanHistoryExt (
	ID int
	,LoanAmount int
	,Term VARCHAR(100)
	,IntrestRate DOUBLE PRECISION
	,Grade CHAR(1)
	,SubGrade CHAR(2)
	,Installment DOUBLE PRECISION
	,EmploymentLength varchar(100)
	,HomeOwnership varchar(100)
	,AnnualIncome DOUBLE PRECISION
	,LoanStatus varchar(100)
	,Purpose varchar(100)
	,State varchar(100)
	,DTI DOUBLE PRECISION
	,LowFico int
	,HighFico int
	,TotalPayment DOUBLE PRECISION
	,LastPaymentMonth date
	,LastPaymentAmount DOUBLE PRECISION
)
WITH
(
    LOCATION='/Loans/History/LoanHistory.parquet'
,   DATA_SOURCE = AzureDataLakeStorageGen1
,   FILE_FORMAT = ParquetFormat
,   REJECT_TYPE = VALUE
,   REJECT_VALUE = 0
);
GO

IF EXISTS (SELECT * FROM sys.tables WHERE name = 'LoanHistory')
	DROP TABLE dbo.LoanHistory

-- select the data into a table
CREATE TABLE dbo.LoanHistory
WITH (DISTRIBUTION = HASH(ID))
AS
SELECT *
FROM dbo.LoanHistoryExt;
GO

-- best to rebuild the columnstore index after loading into sql dw
ALTER INDEX ALL ON dbo.LoanHistory REBUILD;
GO


SELECT COUNT(*)
FROM dbo.LoanHistory


SELECT grade, AVG(IntrestRate)
FROM dbo.LoanHistory
GROUP BY grade
ORDER BY grade	