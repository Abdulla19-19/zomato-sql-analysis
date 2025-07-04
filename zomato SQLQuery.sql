select * from customers
select * from deliveries
select * from orders
select * from restaurants
select * from riders


alter table orders
add constraint fk_customers foreign key(customer_id) 
references customers(customer_id)

alter table orders
add constraint fk_restaurant
foreign key (restaurant_id) 
references restaurants(restaurant_id)


alter table deliveries
add constraint fk_orders 
foreign key(order_id) references orders(order_id)

alter table riders
add constraint fk_riders
foreign key (rider_id) references riders(rider_id)


--EDA
select * from customers
select * from restaurants
select * from orders
select * from riders
select * from deliveries

select count(*) from customers
where customer_id is null or reg_date is null

select count(*) from restaurants
where restaurant_name is null
or 
city is null
or 
opening_hours is null


select count(*) from orders
where
order_item is null
or 
order_date is null
or 
order_time is null
or 
order_status is null
or 
total_amount is null

--1. Get the number of orders and total amount spent per customer in 2024
SELECT 
    c.customer_id,
    c.customer_name,
    COUNT(o.order_id) AS total_orders,
    SUM(o.total_amount) AS total_spent
FROM customers AS c
JOIN orders AS o ON c.customer_id = o.customer_id
WHERE YEAR(o.order_date) = 2024
GROUP BY c.customer_id, c.customer_name
ORDER BY total_spent DESC;





-- 2. Popular Time Slots
-- Question: Identify the time slots during which the most orders are placed. based on 2-hour intervals.

SELECT 
    FLOOR(DATEPART(HOUR, order_time) / 2.0) * 2 AS start_time,
    FLOOR(DATEPART(HOUR, order_time) / 2.0) * 2 + 2 AS end_time,
    COUNT(*) AS total_orders
FROM orders
GROUP BY 
    FLOOR(DATEPART(HOUR, order_time) / 2.0) * 2,
    FLOOR(DATEPART(HOUR, order_time) / 2.0) * 2 + 2
ORDER BY total_orders DESC;



-- 3. Order Value Analysis
-- Question: Find the average order value per customer who has placed more than 750 orders.
-- Return customer_name, and aov(average order value)

select 
	
	c.customer_name,
	avg(o.total_amount) as aov
from orders o
	join customers c
	on c.customer_id = o.customer_id
group by c.customer_name
having  count(o.order_id) > 750



-- 4. High-Value Customers
-- Question: List the customers who have spent more than 100K in total on food orders.
-- return customer_name, and customer_id!


select
	c.customer_name,
	sum(o.total_amount) as total_spent
from orders o
	JOIN customers c
	on c.customer_id = o.customer_id
group by c.customer_name
having sum(o.total_amount) > 100000



-- 5. Orders Without Delivery
-- Question: Write a query to find orders that were placed but not delivered. 
-- Return each restuarant name, city and number of not delivered orders 

SELECT 
	r.restaurant_name,
	COUNT(*)
from orders o
LEFT JOIN 
restaurants as r
on r.restaurant_id = o.restaurant_id
where 
	o.order_id not in (select order_id from deliveries)
group by r.restaurant_name
order by 2 desc



/*
 Q. 6 Restaurant Revenue Ranking: 
 Rank restaurants by their total revenue from the last year, including their name, 
 total revenue, and rank within their city.
*/
WITH ranking_table AS (
    SELECT 
        r.city,
        r.restaurant_name,
        SUM(o.total_amount) AS revenue,
        RANK() OVER (PARTITION BY r.city ORDER BY SUM(o.total_amount) DESC) AS rank
    FROM orders o
    JOIN restaurants r ON r.restaurant_id = o.restaurant_id
    GROUP BY r.city, r.restaurant_name
)
SELECT 
    city,
    restaurant_name,
    revenue
FROM ranking_table
WHERE rank = 1;


/*
 Q. 7
 Most Popular Dish by City: 
Identify the most popular dish in each city based on the number of orders.
*/

SELECT * 
FROM (
    SELECT 
        r.city,
        o.order_item AS dish,
        COUNT(o.order_id) AS total_orders,
        RANK() OVER (PARTITION BY r.city ORDER BY COUNT(o.order_id) DESC) AS rank
    FROM orders AS o
    JOIN restaurants AS r ON r.restaurant_id = o.restaurant_id
    GROUP BY r.city, o.order_item
) AS t1
WHERE rank = 1;



-- Q.8 Customer Churn: 
-- Find customers who haven’t placed an order in 2024 but did in 2023.

-- find cx who has done orders in 2023
-- find cx who has not done orders in 2024
-- compare 1 and 2
SELECT DISTINCT customer_id 
FROM orders
WHERE 
    YEAR(order_date) = 2023
    AND customer_id NOT IN (
        SELECT DISTINCT customer_id 
        FROM orders 
        WHERE YEAR(order_date) = 2024
    );





-- Q.9 Cancellation Rate Comparison: 
-- Calculate and compare the order cancellation rate for each restaurant between the 
-- current year and the previous year.
WITH cancel_ratio_23 AS (
    SELECT 
        o.restaurant_id,
        COUNT(o.order_id) AS total_orders,
        COUNT(CASE WHEN d.delivery_id IS NULL THEN 1 END) AS not_delivered
    FROM orders AS o
    LEFT JOIN deliveries AS d 
        ON o.order_id = d.order_id
    WHERE YEAR(o.order_date) = 2023
    GROUP BY o.restaurant_id
),
cancel_ratio_24 AS (
    SELECT 
        o.restaurant_id,
        COUNT(o.order_id) AS total_orders,
        COUNT(CASE WHEN d.delivery_id IS NULL THEN 1 END) AS not_delivered
    FROM orders AS o
    LEFT JOIN deliveries AS d 
        ON o.order_id = d.order_id
    WHERE YEAR(o.order_date) = 2024
    GROUP BY o.restaurant_id
),
last_year_data AS (
    SELECT 
        restaurant_id,
        total_orders,
        not_delivered,
        ROUND(CAST(not_delivered AS FLOAT) / NULLIF(total_orders, 0) * 100, 2) AS cancel_ratio
    FROM cancel_ratio_23
),
current_year_data AS (
    SELECT 
        restaurant_id,
        total_orders,
        not_delivered,
        ROUND(CAST(not_delivered AS FLOAT) / NULLIF(total_orders, 0) * 100, 2) AS cancel_ratio
    FROM cancel_ratio_24
)

SELECT 
    c.restaurant_id,
    c.cancel_ratio AS current_year_cancel_ratio,
    l.cancel_ratio AS last_year_cancel_ratio
FROM current_year_data AS c
JOIN last_year_data AS l 
    ON c.restaurant_id = l.restaurant_id;



-- Q.10 Rider Average Delivery Time: 
-- Determine each rider's average delivery time.

SELECT 
    o.order_id,
    o.order_time,
    d.delivery_time,
    d.rider_id,
    DATEDIFF(MINUTE, o.order_time, d.delivery_time) AS time_difference_mins
FROM orders AS o
JOIN deliveries AS d 
    ON o.order_id = d.order_id
WHERE d.delivery_status = 'Delivered';



-- Q.11 Monthly Restaurant Growth Ratio: 
-- Calculate each restaurant's growth ratio based on the total number of delivered orders since its joining
WITH growth_ratio AS (
    SELECT 
        o.restaurant_id,
        YEAR(o.order_date) AS year,
        MONTH(o.order_date) AS month,
        COUNT(o.order_id) AS cr_month_orders,
        LAG(COUNT(o.order_id)) OVER (
            PARTITION BY o.restaurant_id 
            ORDER BY YEAR(o.order_date), MONTH(o.order_date)
        ) AS prev_month_orders
    FROM orders AS o
    JOIN deliveries AS d ON o.order_id = d.order_id
    WHERE d.delivery_status = 'Delivered'
    GROUP BY o.restaurant_id, YEAR(o.order_date), MONTH(o.order_date)
)

SELECT
    restaurant_id,
    month,
    prev_month_orders,
    cr_month_orders,
    ROUND(
        CAST((cr_month_orders - prev_month_orders) AS FLOAT) / 
        NULLIF(prev_month_orders, 0) * 100, 2
    ) AS growth_ratio
FROM growth_ratio;




-- Q.12 Customer Segmentation: 
-- Customer Segmentation: Segment customers into 'Gold' or 'Silver' groups based on their total spending 
-- compared to the average order value (AOV). If a customer's total spending exceeds the AOV, 
-- label them as 'Gold'; otherwise, label them as 'Silver'. Write an SQL query to determine each segment's 
-- total number of orders and total revenue

-- cx total spend
-- aov
-- gold
-- silver
-- each category and total orders and total rev

-- Step 1: Calculate AOV (Average Order Value)
WITH avg_order_value AS (
    SELECT AVG(total_amount) AS aov FROM orders
),

-- Step 2: Categorize each customer based on total spend vs AOV
customer_segments AS (
    SELECT 
        o.customer_id,
        SUM(o.total_amount) AS total_spent,
        COUNT(o.order_id) AS total_orders,
        CASE 
            WHEN SUM(o.total_amount) > (SELECT aov FROM avg_order_value) THEN 'Gold'
            ELSE 'Silver'
        END AS cx_category
    FROM orders o
    GROUP BY o.customer_id
)

-- Step 3: Aggregate by customer category
SELECT 
    cx_category,
    SUM(total_orders) AS total_orders,
    SUM(total_spent) AS total_revenue
FROM customer_segments
GROUP BY cx_category;


-- Q.13 Rider Monthly Earnings: 
-- Calculate each rider's total monthly earnings, assuming they earn 8% of the order amount.
SELECT 
    d.rider_id,
    FORMAT(o.order_date, 'MM-yy') AS month,
    SUM(o.total_amount) AS revenue,
    ROUND(SUM(o.total_amount) * 0.08, 2) AS riders_earning
FROM orders AS o
JOIN deliveries AS d ON o.order_id = d.order_id
GROUP BY d.rider_id, FORMAT(o.order_date, 'MM-yy')
ORDER BY d.rider_id, FORMAT(o.order_date, 'MM-yy');




-- Q.14 Rider Ratings Analysis: 
-- Find the number of 5-star, 4-star, and 3-star ratings each rider has.
-- riders receive this rating based on delivery time.
-- If orders are delivered less than 15 minutes of order received time the rider get 5 star rating,
-- if they deliver 15 and 20 minute they get 4 star rating 
-- if they deliver after 20 minute they get 3 star rating.

SELECT 
    rider_id,
    stars,
    COUNT(*) AS total_stars
FROM (
    SELECT 
        d.rider_id,
        DATEDIFF(MINUTE, o.order_time, d.delivery_time) AS delivery_took_time,
        CASE 
            WHEN DATEDIFF(MINUTE, o.order_time, d.delivery_time) < 15 THEN '5 star'
            WHEN DATEDIFF(MINUTE, o.order_time, d.delivery_time) BETWEEN 15 AND 20 THEN '4 star'
            ELSE '3 star'
        END AS stars
    FROM orders AS o
    JOIN deliveries AS d ON o.order_id = d.order_id
    WHERE d.delivery_status = 'Delivered'
) AS t
GROUP BY rider_id, stars
ORDER BY rider_id, total_stars DESC;


-- Q.15 Order Frequency by Day: 
-- Analyze order frequency per day of the week and identify the peak day for each restaurant.

WITH order_by_day AS (
    SELECT 
        r.restaurant_name,
        DATENAME(WEEKDAY, o.order_date) AS day,
        COUNT(o.order_id) AS total_orders,
        RANK() OVER (
            PARTITION BY r.restaurant_name 
            ORDER BY COUNT(o.order_id) DESC
        ) AS rank
    FROM orders AS o
    JOIN restaurants AS r ON o.restaurant_id = r.restaurant_id
    GROUP BY r.restaurant_name, DATENAME(WEEKDAY, o.order_date)
)

SELECT *
FROM order_by_day
WHERE rank = 1
ORDER BY restaurant_name;





-- Q.16 Customer Lifetime Value (CLV): 
-- Calculate the total revenue generated by each customer over all their orders.
SELECT 
    o.customer_id,
    c.customer_name,
    SUM(o.total_amount) AS CLV
FROM orders AS o
JOIN customers AS c ON o.customer_id = c.customer_id
GROUP BY o.customer_id, c.customer_name
ORDER BY CLV DESC;




-- Q.17 Monthly Sales Trends: 
-- Identify sales trends by comparing each month's total sales to the previous month.

WITH monthly_sales AS (
    SELECT 
        YEAR(order_date) AS year,
        MONTH(order_date) AS month,
        SUM(total_amount) AS total_sale
    FROM orders
    GROUP BY YEAR(order_date), MONTH(order_date)
)

SELECT 
    year,
    month,
    total_sale,
    LAG(total_sale) OVER (ORDER BY year, month) AS prev_month_sale
FROM monthly_sales
ORDER BY year, month;





-- Q.18 Rider Efficiency: 
-- Evaluate rider efficiency by determining average delivery times and identifying those with the lowest and highest averages.

-- Step 1: Calculate delivery time in minutes for each delivered order
WITH delivery_times AS (
    SELECT 
        d.rider_id,
        DATEDIFF(MINUTE, o.order_time, d.delivery_time) AS time_delivered
    FROM orders AS o
    JOIN deliveries AS d ON o.order_id = d.order_id
    WHERE d.delivery_status = 'Delivered'
),

-- Step 2: Average delivery time per rider
riders_avg_time AS (
    SELECT 
        rider_id,
        AVG(time_delivered) AS avg_time
    FROM delivery_times
    GROUP BY rider_id
)

-- Step 3: Get rider(s) with MIN and MAX average time
SELECT 
    MIN(avg_time) AS fastest_avg_time,
    MAX(avg_time) AS slowest_avg_time
FROM riders_avg_time;


-- Q.19 Order Item Popularity: 
-- Track the popularity of specific order items over time and identify seasonal demand spikes.
-- Step 1: Calculate delivery time (in minutes) for each order
SELECT 
    order_item,
    season,
    COUNT(order_id) AS total_orders
FROM (
    SELECT 
        order_item,
        order_id,
        MONTH(order_date) AS month,
        CASE 
            WHEN MONTH(order_date) BETWEEN 4 AND 6 THEN 'Spring'
            WHEN MONTH(order_date) BETWEEN 7 AND 8 THEN 'Summer'
            ELSE 'Winter'
        END AS season
    FROM orders
) AS seasonal_orders
GROUP BY order_item, season
ORDER BY order_item, total_orders DESC;




-- Q.20 Rank each city based on the total revenue for last year 2023 

SELECT 
    r.city,
    SUM(o.total_amount) AS total_revenue,
    RANK() OVER (ORDER BY SUM(o.total_amount) DESC) AS city_rank
FROM orders o
JOIN restaurants r ON o.restaurant_id = r.restaurant_id
GROUP BY r.city;


-- End of Reports

