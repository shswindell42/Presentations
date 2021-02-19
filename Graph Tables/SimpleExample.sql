use master
go

drop database if exists graphdemo
go

create database graphdemo
go

use graphdemo
go

create table Person (
	ID INT PRIMARY KEY,
	Name VARCHAR(100)
) AS NODE;

CREATE TABLE Resturant (
	ID INT NOT NULL,
	Name varchar(100),
	City varchar(100)
) AS NODE;

CREATE TABLE City (
	ID INT PRIMARY KEY,
	Name VARCHAR(100),
	stateName VARCHAR(100)
) AS NODE;

-- create edge tables
CREATE TABLE likes (rating int) as edge;
create table friendOf as edge;
create table livesIn as edge;
create table locatedIn as edge;

-- insert data into node tables
insert into Person 
VALUES 
(1,'John'),
(2,'Mary'),
(3,'Alice'),
(4,'Jacob'),
(5,'Julie')

insert into Resturant
values
(1,'Taco Dell', 'Bellevue'),
(2, 'Ginger and Spice', 'Seattle'),
(3, 'Noodle Land', 'Redmond');

insert into City
values
(1, 'Bellevue', 'wa'),
(2, 'Seattle', 'wa'),
(3, 'Redmond', 'wa')

-- insert into edge table
insert into likes 
values
((select $node_id from Person where id = 1), (select $node_id from Resturant where id = 1), 9),
((select $node_id from Person where id = 2), (select $node_id from Resturant where id = 2), 9),
((select $node_id from Person where id = 3), (select $node_id from Resturant where id = 3), 9),
((select $node_id from Person where id = 4), (select $node_id from Resturant where id = 3), 9),
((select $node_id from Person where id = 5), (select $node_id from Resturant where id = 3), 9)

insert into livesIn
values
((select $node_id from Person where id = 1), (select $node_id from City where id = 1)),
((select $node_id from Person where id = 2), (select $node_id from City where id = 2)),
((select $node_id from Person where id = 3), (select $node_id from City where id = 3)),
((select $node_id from Person where id = 4), (select $node_id from City where id = 3)),
((select $node_id from Person where id = 5), (select $node_id from City where id = 1))


insert into locatedIn
values
((select $node_id from Resturant where id = 1), (select $node_id from city where id = 1)),
((select $node_id from Resturant where id = 2), (select $node_id from city where id = 2)),
((select $node_id from Resturant where id = 3), (select $node_id from city where id = 3))

insert into friendOf 
values
((select $node_id from Person where ID = 1), (select $node_id from Person where id = 2)),
((select $node_id from Person where ID = 2), (select $node_id from Person where id = 3)),
((select $node_id from Person where ID = 3), (select $node_id from Person where id = 1)),
((select $node_id from Person where ID = 4), (select $node_id from Person where id = 2)),
((select $node_id from Person where ID = 5), (select $node_id from Person where id = 4))

-- find resturants that john likes
select Resturant.Name
from Person, likes, Resturant
where match (Person-(likes)->Resturant)
and Person.Name = 'John'

select p2.name, Resturant.name
from Person p1, Person p2, likes, friendOf, Resturant
where MATCH(p1-(friendOf)->p2-(likes)->Resturant)
and p1.name = 'John'

