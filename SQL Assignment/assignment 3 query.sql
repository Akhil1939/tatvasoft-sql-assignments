use Assignment_3
go

-- 1. write a SQL query to find Employees who have the biggest salary in their Department
select dp.dep_id,dp.dep_name,  ep.emp_name, ISNULL(ep.salary,0) 'Salary' 
from Department dp
left join Employees ep on ep.dep_id = dp.dep_id
where 
(ep.emp_id in 
(select emp_id from Employees where CONCAT(CAST(dep_id as nvarchar(4)),CAST(salary as nvarchar(8))) in (select CONCAT(CAST(dep_id as nvarchar(4)),CAST(MAX(salary) as nvarchar(8))) as "sal"  from Employees group by dep_id))) 
or 
ep.salary is null;

-- 2. write a SQL query to find Departments that have less than 3 people in it
select d.dep_id, isnull(count(e.emp_id), 0) as 'count'
from dbo.Employees e
right join Department d
on d.dep_id=e.dep_id
group by d.dep_id
having count(emp_id) < 3;
go

-- 3. write a SQL query to find All Department along with the number of people there
select d.dep_id, d.dep_name,count(e.emp_id) as 'no. of employee'
from dbo.Employees e
right join Department d on d.dep_id = e.dep_id
group by d.dep_id, d.dep_name;
go

-- 4. write a SQL query to find All Department along with the total salary there
select d.dep_id, d.dep_name, isnull(SUM(e.salary), 0.00) as 'salary'
from dbo.Employees e
right join Department d on d.dep_id = e.dep_id
group by d.dep_id, d.dep_name;
go