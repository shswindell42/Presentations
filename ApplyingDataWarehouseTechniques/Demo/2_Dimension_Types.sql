---------------------------------------------------
-- Dimension Type Examples
-- Shows Type I and Type II dimensions
---------------------------------------------------

-- Type I - new rows add, update old rows (overwrite)
select *
from Freddie.dim.LoanAttributes

-- Type II - new rows added, add updated rows with new key
select *
from WideWorldImportersDW.Dimension.City
where [WWI City ID] = 9258

-- demo showing the effect on the data when queried
select f.[Order Date Key]
	,c.[Sales Territory]
	,SUM([Total Excluding Tax]) as TotalSales
from [Fact].[Order] f
	inner join [Dimension].City c
		on f.[City Key] = c.[City Key]
where [WWI City ID] = 9258
group by f.[Order Date Key], c.[Sales Territory]
order by 1,2