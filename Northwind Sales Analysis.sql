USE northwind;

-- Total Sales Split by Customer Name
SELECT  concat(customers.FirstName, " ", customers.LastName) AS 'Customer Name',	
        orders.OrderID, 
        orderdetails.UnitPrice, 
        orderdetails.Quantity,
        SUM(orderdetails.UnitPrice * orderdetails.Quantity) AS 'Total Sales'
FROM customers
JOIN orders 
		ON orders.CustomerID = customers.CustomerID
JOIN orderdetails 
		ON orders.OrderID = orderdetails.OrderID
GROUP BY customers.FirstName, 
		customers.LastName,	
        orders.OrderID, 
        orderdetails.UnitPrice, 
        orderdetails.Quantity
ORDER BY SUM(orderdetails.UnitPrice * orderdetails.Quantity) desc
;

-- View of Employees Total Orders and Sales
CREATE OR REPLACE VIEW Employee_Orders_and_Sales AS
SELECT employees.lastname, 
		employees.firstname, 
		COUNT(DISTINCT(orders.orderid)) AS 'No of Orders', 
		ROUND(SUM(orderdetails.unitprice * orderdetails.quantity),2) AS 'Total Sales'
FROM orders
JOIN employees
	ON orders.employeeid = employees.employeeid
JOIN orderdetails
	ON orders.orderid = orderdetails.orderid
GROUP BY employees.lastname, employees.firstname
ORDER BY SUM(orderdetails.unitprice * orderdetails.quantity) DESC
;

-- Stored Function including Unit Price Category
DELIMITER //
CREATE FUNCTION Price_Category (UnitPrice INT)
RETURNS VARCHAR(30) DETERMINISTIC
BEGIN
    DECLARE Price_Category VARCHAR(30);

    IF UnitPrice > 0 AND UnitPrice <= 50 THEN
        SET Price_Category = 'low priced goods';
	ELSEIF UnitPrice > 50 AND UnitPrice <= 150 THEN
		SET Price_Category = 'middle priced goods';
    ELSEIF UnitPrice > 150 THEN
        SET Price_Category = 'high priced goods';
    END IF;

    RETURN Price_Category;
    
END//
DELIMITER ;

SELECT orderid, productid, unitprice, quantity, Price_Category(UnitPrice) As price_category -- Calling Stored Function (Price_Category)
FROM orderdetails;

-- Average Employees Freight
SELECT AVG(Average_freight) AS 'Average freight by Employees'
FROM  
	(SELECT orders.employeeid, 
			employees.firstname, 
            employees.lastname, 
            AVG(orders.freight) AS Average_Freight
	  FROM orders
      JOIN employees
			ON orders.employeeid = employees.employeeid
      GROUP BY orders.employeeid, employees.firstname, employees.lastname
	  ) AS Agg_table
;

-- Total Freight split by Ship City
SELECT  ShipCity AS 'Ship City', 
		SUM(Freight) AS 'Total Freight'
FROM orders
GROUP BY ShipCity
ORDER BY ShipCity
;

-- Total Freight split by Employee Full Name
SELECT  employees.EmployeeID,
		concat(employees.FirstName, " ", employees.LastName) AS 'Full Name',
        ROUND(SUM(orders.Freight),2) AS 'Total Freight'
FROM employees
JOIN orders 
	ON orders.EmployeeID = employees.EmployeeID
GROUP BY employees.EmployeeID,
		employees.FirstName,
        employees.LastName
ORDER BY employees.EmployeeID
;

-- Orders for Shipper Company (Speedy Express)
SELECT orderid, shipvia, freight, shipcity, shipcountry
FROM orders
WHERE shipvia IN
				(SELECT shipperid
					FROM shippers
                    WHERE shipperid = 1)
;

-- Total Freight by Shipping Company
SELECT *
FROM 
	(SELECT orders.shipvia, shippers.companyname, SUM(freight) AS 'Total Freight'
		FROM orders
        JOIN shippers 
				ON shippers.shipperid = orders.shipvia
        GROUP BY orders.shipvia, shippers.companyname
        ORDER BY SUM(freight) DESC
        ) AS ship_table
;

-- View of Employees Total Sales by Product Name
CREATE VIEW Employees_Sale_by_Product AS
SELECT employees.firstname, 
		employees.lastname, 
        products.productname,
		SUM(orderdetails.unitprice * orderdetails.quantity) AS 'Total Sales'
FROM orderdetails
JOIN orders 
		ON orders.orderid = orderdetails.orderid
JOIN employees 
		ON employees.employeeid = orders.employeeid
JOIN products
		ON products.productid = orderdetails.productid
GROUP BY employees.firstname, employees.lastname, products.productname
ORDER BY products.productname
;

-- View of Total sales split by Supplier and Category
CREATE VIEW Sales_by_Suppler_and_Category AS
SELECT  categories.CategoryID,
		categories.CategoryName AS 'Category Name',
        suppliers.CompanyName AS 'Supplier Name',
        SUM(orderdetails.UnitPrice * orderdetails.Quantity) AS 'Total Sales'
FROM products
JOIN categories 
		ON categories.CategoryID = products.CategoryID
JOIN suppliers 
		ON suppliers.SupplierID = products.SupplierID
JOIN orderdetails 
		ON orderdetails.ProductID = products.ProductID
GROUP BY categories.CategoryID,
		categories.CategoryName,
        suppliers.CompanyName
ORDER BY categories.CategoryID
;

-- Total Sales, Average Quatity, Total Profit, Profit Margin, split by Product
SELECT  products.ProductName,
		SUM(orderdetails.UnitPrice * orderdetails.Quantity) AS 'Total Sales',
        ROUND(AVG(orderdetails.Quantity),1) AS 'Average Quantity',
        ROUND(SUM(orderdetails.UnitPrice * orderdetails.Quantity) - 
							SUM(products.UnitPrice * orderdetails.Quantity),1) 
							AS 'Total Profit',
        ROUND((SUM(orderdetails.UnitPrice * orderdetails.Quantity) - 
							SUM(products.UnitPrice * orderdetails.Quantity))/
							SUM(orderdetails.UnitPrice * orderdetails.Quantity) * 100,2) 
							AS 'Profit Margin'
FROM orderdetails
JOIN products 
		ON products.ProductID = orderdetails.ProductID
GROUP BY products.ProductName
ORDER BY products.ProductName
;

-- Updating Products with Category
ALTER TABLE products
ADD Category varchar(255);

UPDATE products
SET Category =
    CASE
        WHEN UnitPrice > 0 AND UnitPrice <= 50 THEN 'Cheap Product'
        WHEN UnitPrice > 50 AND UnitPrice <= 150 THEN 'Average Product'
        WHEN UnitPrice > 150 THEN 'Expensive Product'
    END;

-- Stored Procedure for Quantity and Category
DELIMITER //
CREATE PROCEDURE Check_Qty_and_Category(IN inputParam INT)
BEGIN
	DECLARE Check_Quantity INT;
    
    IF inputParam IS NULL THEN 
		SELECT 'No parameter provided';
    ELSE
        SELECT ProductName, UnitsinStock, Category
        FROM products
		WHERE productid = inputParam;
    END IF;
    
END //
DELIMITER ;

CALL Check_Qty_and_Category(14) -- Calling Stored Procedure (Check_Quantity_and_Category)

