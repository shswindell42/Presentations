------------------------------------------
--- Fact examples
--------------------------------------------
use Freddie
go

-- one row per loan
select top 100 *
from fact.LoanOrigination
WHERE LoanSequenceNumber = 'F108Q1000062'

-- one row per loan payment
select top 100 *
from fact.LoanService
WHERE LoanSequenceNumber = 'F108Q1000062'


-- these tables can get big over time
select count(*)
from fact.LoanOriginationFull

select count(*)
from fact.LoanServiceFull


