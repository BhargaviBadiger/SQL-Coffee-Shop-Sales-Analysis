CREATE DATABASE IF NOT EXISTS monday_coffee;

DROP TABLE IF EXISTS sales;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS city;

CREATE TABLE city
(
	city_id	INT PRIMARY KEY,
	city_name VARCHAR(15),	
	population	BIGINT,
	estimated_rent	FLOAT,
	city_rank INT
);

CREATE TABLE customers
(
	customer_id INT PRIMARY KEY,	
	customer_name VARCHAR(25),	
	city_id INT,
	CONSTRAINT fk_city FOREIGN KEY (city_id) REFERENCES city(city_id)
);


CREATE TABLE products
(
	product_id	INT PRIMARY KEY,
	product_name VARCHAR(35),	
	Price float
);


CREATE TABLE sales
(
	sale_id	INT PRIMARY KEY,
	sale_date	date,
	product_id	INT,
	customer_id	INT,
	total FLOAT,
	rating INT,
	CONSTRAINT fk_products FOREIGN KEY (product_id) REFERENCES products(product_id),
	CONSTRAINT fk_customers FOREIGN KEY (customer_id) REFERENCES customers(customer_id) 
);


SELECT * FROM city;
SELECT * FROM products;
SELECT * FROM customers;
SELECT * FROM sales;


 -- Q1 How many people in each city are estimated to consume coffee, given that 25% of the population does?

SELECT city_name, ROUND((population*0.25)/1000000,2) AS Consumers_in_millions, city_rank 
FROM city
ORDER BY 2 DESC;

SELECT city_name, ROUND((population*0.25)/1000000,2) AS city_population_in_millions,city_rank
FROM city
ORDER BY population DESC;

 -- Q2 What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?

SELECT CI.city_name, SUM(S.total)  AS Total_revenue
FROM sales AS S
JOIN customers as C
ON S.customer_id = C.customer_id
JOIN city AS CI
ON CI.city_id = C.city_id
WHERE YEAR(S.sale_date) = 2023 AND QUARTER(S.sale_date) = 4
GROUP BY CI.city_name
ORDER BY 2 DESC;

-- Q3 How many units of each coffee product have been sold?

SELECT P.product_name, COUNT(S.sale_id) AS Total_orders
FROM products AS P
LEFT JOIN sales AS S 
ON P.product_id = S.product_id
GROUP BY 1
ORDER BY 2 DESC;

 -- Q4  What is the average sales amount per customer in each city?
SELECT CI.city_name, 
SUM(S.total)  AS Total_revenue,
COUNT(DISTINCT S.customer_id) AS Total_cust,
ROUND((SUM(S.total) / COUNT(DISTINCT S.customer_id)),2) AS Avg_sales
FROM sales AS S
JOIN customers as C
ON S.customer_id = C.customer_id
JOIN city AS CI
ON CI.city_id = C.city_id
GROUP BY CI.city_name
ORDER BY 2 DESC; 

-- Q5 City Population and Coffee Consumers (25%)
-- Provide a list of cities along with their populations and estimated coffee consumers.
-- return city_name, total current cx, estimated coffee consumers (25%)
WITH city_table AS
(
SELECT city_name, ROUND((population*0.25)/1000000,2) AS Consumers_in_millions
FROM city
),
customers_table AS
(
SELECT CI.city_name, 
COUNT(DISTINCT C.customer_id) AS unique_cust
FROM sales AS S
JOIN customers as C
ON S.customer_id = C.customer_id
JOIN city AS CI
ON CI.city_id = C.city_id
GROUP BY 1
)

SELECT 
ct.city_name,
Consumers_in_millions,
unique_cust
FROM city_table AS ct
JOIN customers_table AS cust
ON ct.city_name = cust.city_name;

-- Q6 What are the top 3 selling products in each city based on sales volume?
SELECT *
FROM
(SELECT CI.city_name, P.product_name, COUNT(S.sale_id) AS Total_orders,
DENSE_RANK() OVER(PARTITION BY CI.city_name ORDER BY COUNT(S.sale_id) DESC) AS rnk
FROM sales AS S
JOIN products AS P
ON S.product_id = P.product_id
JOIN customers AS C
ON C.customer_id = S.customer_id
JOIN city AS CI
ON CI.city_id = C.city_id
GROUP BY 1, 2) AS temp
WHERE rnk <= 3;

-- Q7 How many unique customers are there in each city who have purchased coffee products?

SELECT CI.city_name, 
COUNT(DISTINCT C.customer_id) AS unique_cust
FROM city AS CI
LEFT JOIN customers AS C
ON CI.city_id = C.city_id
JOIN sales AS S
ON S.customer_id = C.customer_id
WHERE S.product_id IN (1,2,3,4,5,6,7,8,9,10,11,12,13,14)
GROUP BY 1;

-- Q8 Find each city and their average sale per customer and avg rent per customer

WITH city_table AS
(
SELECT CI.city_name, 
SUM(S.total)  AS Total_revenue,
COUNT(DISTINCT S.customer_id) AS Total_cust,
ROUND((SUM(S.total) / COUNT(DISTINCT S.customer_id)),2) AS Avg_sales_per_cust
FROM sales AS S
JOIN customers as C
ON S.customer_id = C.customer_id
JOIN city AS CI
ON CI.city_id = C.city_id
GROUP BY CI.city_name
ORDER BY 2 DESC
),
city_rent AS
(
SELECT
   city_name,
   estimated_rent
FROM city
)
SELECT 
cr.city_name,
cr.estimated_rent,
ct.Total_cust,
ct.Avg_sales_per_cust,
ROUND((cr.estimated_rent/ct.Total_cust),2) AS Avg_rent_per_cust
FROM city_rent AS cr
JOIN city_table AS ct
ON cr.city_name = ct.city_name
ORDER BY 5 DESC;

-- Q9 Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly) by each city
WITH monthly_sales AS
(
SELECT CI.city_name, MONTH(sale_date) AS month, YEAR(sale_date) AS year,
SUM(S.total)  AS Total_revenue
FROM sales AS S
JOIN customers as C
ON S.customer_id = C.customer_id
JOIN city AS CI
ON CI.city_id = C.city_id
GROUP BY 1,2,3
ORDER BY 1,2,3
),
growth_ratio AS
(
SELECT city_name, month, year, Total_revenue AS cr_month_sale,
LAG(Total_revenue,1) OVER(PARTITION BY city_name ORDER BY year, month) AS last_month_sale
FROM monthly_sales
)
SELECT city_name, month, year, cr_month_sale, last_month_sale, ROUND((cr_month_sale-last_month_sale)/last_month_sale*100,2) AS growth_ratio
FROM growth_ratio
WHERE last_month_sale IS NOT NULL;

-- Q10 Market Potential Analysis
-- Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated coffee consumer

WITH city_table AS
(
SELECT CI.city_name, 
SUM(S.total)  AS Total_revenue,
COUNT(DISTINCT S.customer_id) AS Total_cust,
ROUND((SUM(S.total) / COUNT(DISTINCT S.customer_id)),2) AS Avg_sales_per_cust
FROM sales AS S
JOIN customers as C
ON S.customer_id = C.customer_id
JOIN city AS CI
ON CI.city_id = C.city_id
GROUP BY CI.city_name
ORDER BY 2 DESC
),
city_rent AS
(
SELECT
   city_name,
   estimated_rent,
   ROUND((population * 0.25)/1000000,3) AS estimated_coffee_consumer_in_millions
FROM city
)
SELECT 
cr.city_name,
Total_revenue,
cr.estimated_rent AS total_rent,
ct.Total_cust,
estimated_coffee_consumer_in_millions,
ct.Avg_sales_per_cust,
ROUND((cr.estimated_rent/ct.Total_cust),2) AS Avg_rent_per_cust
FROM city_rent AS cr
JOIN city_table AS ct
ON cr.city_name = ct.city_name
ORDER BY 2 DESC;




  
  