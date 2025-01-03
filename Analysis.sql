select * from city ;
select * from customers ;
select * from products ;
select * from sales ;

-- 1.Coffee Consumers Count
-- How many people in each city are estimated to consume coffee, given that 25% of the population does?
SELECT 
	city_name,
	round((Population * 0.25) / 1000000,2) as Consumtion_in_millions  ,
	city_rank
FROM city 
ORDER BY population DESC ;

-- 2.Total Revenue from Coffee Sales
-- What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?
SELECT 
	city_name,
	SUM(total) as total_sales
FROM sales s
JOIN customers cu on s.customer_id=cu.customer_id
JOIN city ci on cu.city_id=ci.city_id
WHERE EXTRACT(QUARTER FROM sale_date) = 4 
AND
EXTRACT(YEAR FROM sale_date) = 2023
GROUP BY city_name
order by total_sales desc
;
-- 3.Sales Count for Each Product
-- How many units of each coffee product have been sold?
SELECT 
	product_name,
	count(*) as Total_SALE_IN_UNIT
FROM sales 
JOIN products USING (product_id)
GROUP BY product_name
ORDER BY Total_SALE_IN_UNIT DESC
;

-- 4.Average Sales Amount per City
-- What is the average sales amount per customer in each city?
SELECT 
	ci.city_name as city,
	sum(s.total) as total_sales,
	count(distinct c.customer_id) as customer_count,
	round(sum(s.total)::numeric /count(distinct c.customer_id),2)
FROM sales s
JOIN customers c ON s.customer_id=c.customer_id  
JOIN city ci ON c.city_id=ci.city_id 
GROUP BY city
order by total_sales desc
;


-- 5.City Population and Coffee Consumers 25%
-- Provide a list of cities along with their populations and estimated coffee consumers.
SELECT 
	city_name,
	round((population * 0.25) / 1000000,2) as total_Poplation
FROM city c
;
SELECT 
	city_name ,
	round((ci.population * 0.25) / 1000000,2) as total_Poplation,
	count(distinct c.customer_id) unique_customers
FROM sales s 
JOIN customers c ON s.customer_id = c.customer_id 
JOIN city ci on c.city_id=ci.city_id 
group by ci.city_name,ci.population 
;

-- 6.Top Selling Products by City
-- What are the top 3 selling products in each city based on sales volume?
with top_products as
(SELECT 
	ci.city_name city_name,
	p.product_name Product_name,
	count(s.sale_id) as Total_sales,
	dense_rank() over(partition by ci.city_name order by count(s.sale_id) desc) as ranking
FROM sales s 
JOIN products p ON s.product_id=p.product_id 
JOIN customers c ON s.customer_id = c.customer_id 
JOIN city ci ON c.city_id=ci.city_id
GROUP BY city_name,Product_name
)
select * from top_products 
WHERE ranking <= 3
;

-- 7.Customer Segmentation by City
-- How many unique customers are there in each city who have purchased coffee products?
select * from products ;

SELECT 
	ci.city_name City_name,
	COUNT(DISTINCT s.customer_id) as Unique_customers
FROM city ci
JOIN customers c ON ci.city_id=c.city_id  
JOIN sales s ON s.customer_id=c.customer_id
JOIN products p ON p.product_id=s.product_id
WHERE p.product_id <= 14
GROUP BY City_name
;	
-- 8.Average Sale vs Rent
-- Find each city and their average sale per customer and avg rent per customer
SELECT 
	ci.city_name as city,
	count(distinct c.customer_id) as customer_count,
	ci.estimated_rent,
	round(sum(s.total)::numeric /count(distinct c.customer_id),2) as avg_sale_per_customer,
	round(ci.estimated_rent::numeric/ 
									count(distinct c.customer_id)::numeric,2) as avg_rant_per_customer
FROM sales s
JOIN customers c ON s.customer_id=c.customer_id  
JOIN city ci ON c.city_id=ci.city_id 
GROUP BY city,ci.estimated_rent
;

-- 9.Monthly Sales Growth
-- Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly).
with Monthly_sale as 
(
SELECT 
	ci.city_name City_Name,
	EXTRACT(MONTH FROM sale_date) as Month,
	EXTRACT(YEAR FROM sale_date) as YEAR,
	SUM(s.total) as total_sales
FROM sales as s 
JOIN customers as c
ON c.customer_id = s.customer_id
JOIN city as ci
ON ci.city_id = c.city_id
GROUP BY 1,2,3
ORDER BY 1,3,2
),
growth_ratio 
AS 
(Select 
	City_Name,
	Month,
	YEAR,
	total_sales as cr_month_sale,
	LAG(total_sales,1) OVER(PARTITION BY city_name ORDER BY YEAR ,MONTH) as last_month_sale
FROM monthly_sale
)
SELECT
	City_Name,
	Month,
	YEAR,
	cr_month_sale,
	last_month_sale,
	round((cr_month_sale - last_month_sale)::numeric / last_month_sale::numeric * 100,2) as growth
FROM growth_ratio
WHERE last_month_sale IS NOT NULL
;	
-- 10.Market Potential Analysis
-- Identify top 3 city based on highest sales, 
-- return city name, total sale, total rent, 
-- total customers, estimated coffee consumer