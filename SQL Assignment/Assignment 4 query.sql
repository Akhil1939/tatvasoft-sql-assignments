USE [Northwind]
GO
--1. Create a stored procedure in the Northwind database that will calculate the average value of Freight for a 
--specified customer.Then, a business rule will be added that will be triggered before every Update and Insert
-- command in the Orders controller,and will use the stored procedure to verify that the Freight does not exceed 
--the average freight. If it does, a message will be displayed and the command will be cancelled.

create procedure sp_ValidateFreight
    -- inputted customer
    @CustomerID nvarchar(5),
    -- returned average freight
    @AverageFreight money output
as
begin
   select @AverageFreight = AVG(Freight) 
   from Orders
   where CustomerID = @CustomerID
end
go

create or alter trigger tr_insteadOfInsert_orders
on Orders
instead of insert
as
begin
	declare @AvgFreight money, @CustomerId nvarchar(5), @insertedFreight money 
	
	select * from inserted;

	select @CustomerId = CustomerId
	from Customers 
	where CustomerID in (select CustomerID from inserted);

	if(@CustomerId is null)
	begin
		Raiserror('Invalid customer id',16,1)
		return		
	end

	select @insertedFreight = Freight
	from inserted;


	exec dbo.sp_ValidateFreight @CustomerID ,@AverageFreight = @AvgFreight output; 

	if(@AvgFreight < @insertedFreight)
	begin
		Raiserror('Inserted Freight amount excluded average freight amount',16,1)
		return
	end

	Print 'tr_insteadOfInsert_orders'
	insert into Orders( CustomerID, EmployeeID, OrderDate, RequiredDate, ShipVia, Freight, ShipName, ShipAddress, ShipCity,ShipPostalCode, ShipCountry)
    select  CustomerID, EmployeeID, OrderDate, RequiredDate, ShipVia, Freight, ShipName, ShipAddress, ShipCity,ShipPostalCode, ShipCountry
	from inserted;

end
go
insert into Orders ( CustomerID, EmployeeID, OrderDate, RequiredDate, ShipVia, Freight, ShipName, ShipAddress, ShipCity,ShipPostalCode, ShipCountry)
values('BONAP',3,'1998-05-12 00:00:00.000','1998-05-24 00:00:00.000',2,16,'Rattlesnake Canyon Grocery','2817 Milton Dr.','Albuquerque',87110, 'USA')


create or alter trigger tr_insteadOfUpdate_orders
on Orders
instead of update
as
begin
	declare @AvgFreight money, @CustomerId nvarchar(5), @insertedFreight money,@deletdFreight money, @OrderId int 
	
	select * from inserted;
	select * from deleted;

	select @CustomerId = CustomerId
	from Customers 
	where CustomerID in (select CustomerID from inserted);

	select @OrderId = OrderId
	from Orders 
	where OrderID in (select OrderID from inserted);

	if(@CustomerId is null or @OrderId is null )
	begin
		Raiserror('Invalid customer or order id',16,1)
		return		
	end

	select @insertedFreight = Freight
	from inserted;
	select @deletdFreight = Freight
	from deleted;
	
	exec dbo.sp_ValidateFreight 'RATTC' ,@AverageFreight = @AvgFreight output;  

	Print 'Deleted Freight ' +  CAST(@deletdFreight as varchar) + ' \n Inserted Freight : ' + CAST(@insertedFreight as varchar) + ' \n Updated : ' + CAST(@AvgFreight as varchar);
	
	if((@insertedFreight <> @deletdFreight) and (@AvgFreight < @insertedFreight))
	begin
		Raiserror('Freight amount excluded',16,1)
		return		
	end

	Print 'tr_insteadOfUpdate_orders'
	
	update Orders
	set Freight = @insertedFreight
	where OrderID = @OrderId;

end
go
update Orders
set Freight = 102
where OrderID = 10248;
go
--2. write a SQL query to Create Stored procedure in the Northwind database to retrieve Employee Sales by Country
create procedure [dbo].[EmployeeSalesbyCountry] @country nvarchar(15)
as
SELECT Employees.Country,Employees.FirstName, Employees.LastName,  Orders.ShippedDate, Orders.OrderID, 
		"Order Subtotals".Subtotal AS SaleAmount
FROM Employees INNER JOIN 
	(Orders INNER JOIN "Order Subtotals" ON Orders.OrderID = "Order Subtotals".OrderID) 
	ON Employees.EmployeeID = Orders.EmployeeID
	where Employees.country = @country

	-- Execute --
DECLARE	@return_value int

EXEC	@return_value = [dbo].[EmployeeSalesbyCountry]
		@country = N'UK'
SELECT	'Return Value' = @return_value
GO

-- 3. write a SQL query to Create Stored procedure in the Northwind database to retrieve Sales by Year

create procedure [dbo].[SalesByYear] 
	@B_Date DateTime, @E_Date DateTime 
	AS
SELECT Orders.ShippedDate, Orders.OrderID, "Order Subtotals".Subtotal, DATENAME(yy,ShippedDate) AS Year
FROM Orders 
INNER JOIN "Order Subtotals" 
ON Orders.OrderID = "Order Subtotals".OrderID
WHERE Orders.ShippedDate Between @B_Date And @E_Date
order by Orders.ShippedDate
-- execute --
DECLARE	@return_value int
EXEC	@return_value = [dbo].[SalesByYear]
		@B_Date = N'1997-1-1',
		@E_Date = N'1998-1-1'
SELECT	'Return Value' = @return_value
GO

-- 4. write a SQL query to Create Stored procedure in the Northwind database to retrieve Sales By Category
create PROCEDURE [dbo].[Sales By Category1]
    @CategoryName nvarchar(15)
AS
SELECT ProductName,
	TotalPurchase=ROUND(SUM(CONVERT(decimal(14,2), OD.Quantity * (1-OD.Discount) * OD.UnitPrice)), 0)
FROM [Order Details] OD, Orders O, Products P, Categories C
WHERE OD.OrderID = O.OrderID 
	AND OD.ProductID = P.ProductID 
	AND P.CategoryID = C.CategoryID
	AND C.CategoryName = @CategoryName
GROUP BY ProductName
ORDER BY ProductName

-- Execute --
DECLARE	@return_value int
EXEC	@return_value = [dbo].[Sales By Category1]
		@CategoryName = N'Dairy Products'
SELECT	'Return Value' = @return_value

-- 5. write a SQL query to Create Stored procedure in the Northwind database to retrieve Ten Most Expensive Products
create PROCEDURE topTenCoastlyProduct
 as
 select top 10 [ProductName], [UnitPrice] from dbo.Products order by UnitPrice DESC;
 select* from Products

-- Execute --
DECLARE	@return_value int
EXEC	@return_value = [dbo].[topTenCoastlyProduct]
SELECT	'Return Value' = @return_value

--6. write a SQL query to Create Stored procedure in the Northwind database to insert Customer Order Details
create procedure insertNewOrder
@OrderID int ,
@ProductID int,
@UnitPrice money,
@Quantity smallInt,
@Discount real
as
insert into [dbo].[Order Details] values (@OrderID, @ProductID, @UnitPrice, @Quantity, @Discount)

--Execute --
DECLARE	@return_value int

EXEC	@return_value = [dbo].[insertNewOrder]
		@OrderID = 10249,
		@ProductID = 74,
		@UnitPrice = 34.80,
		@Quantity = 4,
		@Discount = 0.00
SELECT	'Return Value' = @return_value

 --7. write a SQL query to Create Stored procedure in the Northwind database to update Customer Order Details
 create procedure UpdateOrder
@OrderID int ,
@ProductID int,
@Quantity smallInt
as
update [dbo].[Order Details] 
set 
Quantity = @Quantity
where OrderId = @OrderID AND ProductId = @ProductID

--execute --
DECLARE	@return_value int
EXEC	@return_value = [dbo].[UpdateOrder]
		@OrderID = 10249,
		@ProductID = 74,
		@Quantity = 2

SELECT	'Return Value' = @return_value
