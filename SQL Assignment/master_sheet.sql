# Q1.A) fetch sales reps reporting to 1102
select * from employees;
select employeeNumber,firstname,lastname from employees
where jobTitle = "sales Rep" and reportsTo=1102; 

# Q1.B) show unique productlines ending with cars
select distinct productline from products where productline like "%cars";


# Q2.A) Segment customers by country into North America, Europe, and Other
SELECT customerNumber,customerName, 
 CASE 
        WHEN country IN ('USA', 'Canada') THEN 'North America'
        WHEN country IN ('UK', 'France', 'Germany') THEN 'Europe'
        ELSE 'Other'
    END AS CustomerSegment FROM customers;
    
    
# Q3.A)Top 10 products by highest total order quantity
SELECT productCode, SUM(quantityOrdered) AS total_quantity
FROM orderdetails
GROUP BY productCode
ORDER BY total_quantity DESC LIMIT 10;

# Q3.B) Payment frequency by month (Only months with > 20 payments)
SELECT MONTHNAME(paymentDate) AS month_name, 
COUNT(*) AS total_payments
FROM payments
GROUP BY month_name
HAVING total_payments > 20
ORDER BY total_payments DESC;

DROP DATABASE IF EXISTS classicmodels;

DROP DATABASE IF EXISTS customers_orders;

#Q4.A) Create Database and Customers table with Constraints
CREATE DATABASE customers_orders;
USE customers_orders;

CREATE TABLE customers (
    customer_id INT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL, -- Fixed constraint
    last_name VARCHAR(50) NOT NULL,  -- Fixed constraint
    email VARCHAR(100),
    phone_number VARCHAR(20),
    country VARCHAR(50));
    
#Q4.B)Create Orders table with Foreign Key and Check Constraints
CREATE TABLE Orders (
    order_id INT PRIMARY KEY,
    customer_id INT,
    order_date DATE,
    total_amount DECIMAL(10, 2),
    CONSTRAINT fk_customer 
        FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    CONSTRAINT chk_total_amount 
        CHECK (total_amount > 0));
INSERT INTO customers (customer_id, first_name, last_name, country)
VALUES 
(112, 'Erik', 'King', 'USA'),
(124, 'Susan', 'Nelson', 'USA'),
(141, 'Diego', 'Freyre', 'Spain'),
(145, 'Janine', 'Labrune', 'France'),
(119, 'Janine', 'Labrune', 'France');


#Q5.A)Top 5 countries by order count
SELECT 
    c.country, 
    COUNT(o.orderNumber) AS order_count
FROM customers_orders.customers c
JOIN classicmodels.orders o ON c.customer_id = o.customerNumber
GROUP BY c.country
ORDER BY order_count DESC
LIMIT 5;

#Q6.A)SELF JOIN
USE Customers_Orders;
CREATE TABLE project (
    EmployeeID INT PRIMARY KEY AUTO_INCREMENT,
    FullName VARCHAR(50) NOT NULL,
    Gender VARCHAR(10) CHECK (Gender IN ('Male', 'Female')),
    ManagerID INT);
    
INSERT INTO project (FullName, Gender, ManagerID) VALUES
('Pranaya', 'Male', 3),
('Priyanka', 'Female', 1),
('Preety', 'Female', NULL),
('Anurag', 'Male', 1),
('Sambit', 'Male', 1),
('Rajesh', 'Male', 3),
('Hina', 'Female', 3);
SELECT 
    e.FullName AS "Employee Name", 
    m.FullName AS "Manager Name"
FROM project e
LEFT JOIN project m ON e.ManagerID = m.EmployeeID;


#Q7. craate the facility table
CREATE TABLE facility (Facility_ID INT,
    Name VARCHAR(100),
    State VARCHAR(100),
    Country VARCHAR(100));
#1. alter to add primary key and auto increment
ALTER TABLE facility MODIFY COLUMN Facility_ID INT PRIMARY KEY AUTO_INCREMENT;
#2. add the city column after name 
ALTER TABLE facility ADD COLUMN City VARCHAR(100) NOT NULL AFTER Name;



#Q8.)Views in SQL

CREATE OR REPLACE VIEW product_category_sales AS
SELECT pl.productLine,
    SUM(od.quantityOrdered * od.priceEach) AS total_sales,
    COUNT(DISTINCT o.orderNumber) AS number_of_orders
FROM classicmodels.productlines pl
JOIN classicmodels.products p ON pl.productLine = p.productLine
JOIN classicmodels.orderdetails od ON p.productCode = od.productCode
JOIN classicmodels.orders o ON od.orderNumber = o.orderNumber
GROUP BY pl.productLine;

SELECT * FROM product_category_sales;

#Q9) call procedures
USE classicmodels;
DROP PROCEDURE IF EXISTS Get_country_payments;
DELIMITER //
CREATE PROCEDURE Get_country_payments(IN input_year INT, IN input_country VARCHAR(50))
BEGIN
    SELECT 
        YEAR(p.paymentDate) AS Year,
        c.country,
        CONCAT(FORMAT(SUM(p.amount) / 1000, 0), 'K') AS "Total Amount"
    FROM customers c
    JOIN payments p ON c.customerNumber = p.customerNumber
    WHERE YEAR(p.paymentDate) = input_year 
      AND c.country = input_country
    GROUP BY Year, c.country;
END //
DELIMITER ;

CALL Get_country_payments(2004, 'France');


#Q10.A) Using customers and orders tables, rank the customers based on their order frequency
USE classicmodels;
SELECT 
    c.customerName, 
    COUNT(o.orderNumber) AS Order_count,
    RANK() OVER (ORDER BY COUNT(o.orderNumber) DESC) AS order_frequency_rnk
FROM customers c
JOIN orders o ON c.customerNumber = o.customerNumber
GROUP BY c.customerName
ORDER BY order_frequency_rnk ASC;

#B)Calculate year wise, month name wise count of orders and year over year (YoY) percentage change
 #Format the YoY values in no decimals and show in % sign.
 USE classicmodels;
WITH MonthlyOrders AS (SELECT 
        YEAR(orderDate) AS Year,
        MONTHNAME(orderDate) AS Month,
        MONTH(orderDate) AS MonthNum,
        COUNT(orderNumber) AS Total_Orders
    FROM orders
    GROUP BY Year, Month, MonthNum
    ORDER BY Year, MonthNum)
SELECT Year,Month,Total_Orders,
    CONCAT(
        ROUND(
            ((Total_Orders - LAG(Total_Orders) OVER (ORDER BY Year, MonthNum)) 
            / LAG(Total_Orders) OVER (ORDER BY Year, MonthNum)) * 100, 0), '%') AS '% YoY Change'
FROM MonthlyOrders;


#11)Find out how many product lines are there for which the buy price value is greater than the average of buy price value.
#Show the output as product line and its count.
SELECT productLine, COUNT(*) AS Total
FROM products
WHERE buyPrice > (SELECT AVG(buyPrice) FROM products)
GROUP BY productLine
ORDER BY Total DESC;


#12)ERROR HANDLING in SQL
USE classicmodels;
drop table emp_EH;
drop procedure insert_Emp_With_Handler;
CREATE TABLE Emp_EH (EmpID INT PRIMARY KEY,EmpName VARCHAR(100),EmailAddress VARCHAR(100));

DELIMITER //

CREATE PROCEDURE Insert_Emp_With_Handler(IN p_EmpID INT, IN p_EmpName VARCHAR(100), IN p_EmailAddress VARCHAR(100))
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        SELECT "Error occurred" AS Message;
    END;

    INSERT INTO Emp_EH (EmpID, EmpName, EmailAddress)
    VALUES (p_EmpID, p_EmpName, p_EmailAddress);
    
    SELECT "Success: Employee added" AS Message;
END //

DELIMITER ;

CALL Insert_Emp_With_Handler(1, 'John Doe', 'john@example.com');
CALL Insert_Emp_With_Handler(1, 'Jane Smith', 'jane@example.com');

#Q13)TRIGGERS
USE classicmodels;

CREATE TABLE Emp_BIT (Name VARCHAR(50),Occupation VARCHAR(50),Working_date DATE,Working_hours INT);
DELIMITER //
CREATE TRIGGER before_insert_working_hours
BEFORE INSERT ON Emp_BIT
FOR EACH ROW
BEGIN
    IF NEW.Working_hours < 0 THEN
        SET NEW.Working_hours = ABS(NEW.Working_hours);
    END IF;
END //
DELIMITER ;
INSERT INTO Emp_BIT VALUES
('Robin', 'Scientist', '2020-10-04', 12),  
('Warner', 'Engineer', '2020-10-04', 10),  
('Peter', 'Actor', '2020-10-04', 13),  
('Marco', 'Doctor', '2020-10-04', 14),  
('Brayden', 'Teacher', '2020-10-04', 12),  
('Antonio', 'Business', '2020-10-04', 11);
INSERT INTO Emp_BIT VALUES ('TestUser', 'Tester', '2025-12-27', -15);
SELECT * FROM Emp_BIT WHERE Name = 'TestUser';
