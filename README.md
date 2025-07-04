## zomato-sql-analysis
![zomato image](https://github.com/user-attachments/assets/783b9e61-0632-4e5d-a9d6-6c5edff7b879)
# Zomato SQL Data Analysis Project: Detailed Analysis Report

This report provides a comprehensive analysis of the Zomato food delivery database, detailing the schema, integrity constraints, exploratory data analysis (EDA), and insights derived from 20 analytical SQL queries. The database captures key entities—customers, restaurants, orders, deliveries, and riders—enabling actionable business intelligence for operational efficiency, customer retention, and revenue optimization.

---

## Database Schema Description

The Zomato database consists of five core tables, each representing a critical component of the food delivery ecosystem. Below is a detailed description of each table, inferred from the provided SQL queries.

### 1. Customers Table
- **Purpose**: Stores information about customers who place orders on the Zomato platform.


### 2. Restaurants Table
- **Purpose**: Contains details about restaurants partnered with Zomato.

### 3. Orders Table
- **Purpose**: Tracks food orders placed by customers.


### 4. Deliveries Table
- **Purpose**: Records delivery details for orders.

### 5. Riders Table
- **Purpose**: Stores information about delivery riders.

---
### Tables relations
![erd](https://github.com/user-attachments/assets/62207678-fc39-441e-9c0e-6338e42b463a)


---

## Exploratory Data Analysis (EDA)

The EDA queries assess data quality by checking for missing values in critical columns, which could impact the reliability of analytical insights.

1. **Customers Table**:
   - **Query**: `SELECT COUNT(*) FROM customers WHERE customer_id IS NULL OR reg_date IS NULL`
   - **Purpose**: Identifies records with missing `customer_id` or `reg_date`, which are essential for customer identification and tracking tenure.
   - **Implication**: Missing values may indicate data entry errors or incomplete profiles, requiring data cleansing to ensure accurate customer analytics.

2. **Restaurants Table**:
   - **Query**: `SELECT COUNT(*) FROM restaurants WHERE restaurant_name IS NULL OR city IS NULL OR opening_hours IS NULL`
   - **Purpose**: Checks for missing restaurant details, critical for operational analytics and customer-facing information.
   - **Implication**: Incomplete data could affect location-based recommendations or operational planning, necessitating validation.

3. **Orders Table**:
   - **Query**: `SELECT COUNT(*) FROM orders WHERE order_item IS NULL OR order_date IS NULL OR order_time IS NULL OR order_status IS NULL OR total_amount IS NULL`
   - **Purpose**: Ensures completeness of order details, as missing values could skew revenue, timing, or status analyses.
   - **Implication**: Missing order data could lead to inaccurate revenue calculations or operational insights, requiring robust data quality checks.

---

## Analytical Queries and Insights

The 20 analytical SQL queries provide actionable insights into customer behavior, restaurant performance, rider efficiency, and operational trends. Below is a detailed analysis of each query, including its purpose, methodology, insights, and business implications.

### 1. Number of Orders and Total Amount Spent per Customer in 2024
- **Query**: Aggregates orders by customer for 2024, calculating total orders and spending.
```
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
```

### 2. Popular Time Slots
- **Query**: Groups orders into 2-hour time slots based on `order_time` to identify peak ordering periods.
```

SELECT 
    FLOOR(DATEPART(HOUR, order_time) / 2.0) * 2 AS start_time,
    FLOOR(DATEPART(HOUR, order_time) / 2.0) * 2 + 2 AS end_time,
    COUNT(*) AS total_orders
FROM orders
GROUP BY 
    FLOOR(DATEPART(HOUR, order_time) / 2.0) * 2,
    FLOOR(DATEPART(HOUR, order_time) / 2.0) * 2 + 2
ORDER BY total_orders DESC;
```

### 3. Order Value Analysis
- **Query**: Computes the average order value (AOV) for customers with over 750 orders.
```
select 
	
	c.customer_name,
	avg(o.total_amount) as aov
from orders o
	join customers c
	on c.customer_id = o.customer_id
group by c.customer_name
having  count(o.order_id) > 750
```
### 4. High-Value Customers
- **Query**: Lists customers with total spending exceeding 100,000.
```
select
	c.customer_name,
	sum(o.total_amount) as total_spent
from orders o
	JOIN customers c
	on c.customer_id = o.customer_id
group by c.customer_name
having sum(o.total_amount) > 100000

```
### 5. Orders Without Delivery
- **Query**: Finds orders placed but not delivered, grouped by restaurant name.
```
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
```
### 6. Restaurant Revenue Ranking
- **Query**: Ranks restaurants by total revenue in 2023 within each city.
```
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


```

### 7. Most Popular Dish by City
- **Query**: Identifies the most popular dish in each city based on order count.
```
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

```
### 8. Customer Churn
- **Query**: Finds customers who ordered in 2023 but not in 2024.
```
SELECT DISTINCT customer_id 
FROM orders
WHERE 
    YEAR(order_date) = 2023
    AND customer_id NOT IN (
        SELECT DISTINCT customer_id 
        FROM orders 
        WHERE YEAR(order_date) = 2024
    );

```
### 9. Cancellation Rate Comparison
- **Query**: Compares order cancellation rates for restaurants between 2023 and 2024.
```
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



```
### 10. Rider Average Delivery Time
- **Query**: Calculates delivery time for each delivered order per rider.
```
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



```


### 11. Monthly Restaurant Growth Ratio
- **Query**: Calculates the month-over-month growth ratio of delivered orders per restaurant.
```
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


```
### 12. Customer Segmentation
- **Query**: Segments customers into 'Gold' or 'Silver' based on total spending compared to the platform’s AOV.
```
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






```
### 13. Rider Monthly Earnings
- **Query**: Calculates riders’ monthly earnings based on 8% of order amounts.
```
SELECT 
    d.rider_id,
    FORMAT(o.order_date, 'MM-yy') AS month,
    SUM(o.total_amount) AS revenue,
    ROUND(SUM(o.total_amount) * 0.08, 2) AS riders_earning
FROM orders AS o
JOIN deliveries AS d ON o.order_id = d.order_id
GROUP BY d.rider_id, FORMAT(o.order_date, 'MM-yy')
ORDER BY d.rider_id, FORMAT(o.order_date, 'MM-yy');


```
### 14. Rider Ratings Analysis
- **Query**: Assigns 5-star (<15 min), 4-star (15-20 min), or 3-star (>20 min) ratings to riders based on delivery times.
```
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


```
### 15. Order Frequency by Day
- **Query**: Identifies the peak ordering day for each restaurant.
```

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

```
### 16. Customer Lifetime Value (CLV)
- **Query**: Calculates total revenue generated by each customer.
```
SELECT 
    o.customer_id,
    c.customer_name,
    SUM(o.total_amount) AS CLV
FROM orders AS o
JOIN customers AS c ON o.customer_id = c.customer_id
GROUP BY o.customer_id, c.customer_name
ORDER BY CLV DESC;




```
### 17. Monthly Sales Trends
- **Query**: Compares monthly sales to the previous month.
```


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




```
### 18. Rider Efficiency
- **Query**: Identifies riders with the lowest and highest average delivery times.
```

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



```
### 19. Order Item Popularity
- **Query**: Tracks the popularity of order items by season (Spring: Apr-Jun, Summer: Jul-Aug, Winter: others).
```
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



```
### 20. City Revenue Ranking
- **Query**: Ranks cities by total revenue in 2023.
```
SELECT 
    r.city,
    SUM(o.total_amount) AS total_revenue,
    RANK() OVER (ORDER BY SUM(o.total_amount) DESC) AS city_rank
FROM orders o
JOIN restaurants r ON o.restaurant_id = r.restaurant_id
GROUP BY r.city;



```
---

## Recommendations

1. **Customer Retention**:
   - **Queries 4, 8, 16**: Target high-value and high-CLV customers with personalized offers, loyalty programs (e.g., Zomato Pro), or VIP perks. Re-engage churned customers with targeted campaigns (e.g., discount codes, personalized emails).
2. **Operational Efficiency**:
   - **Queries 2, 5, 15**: Optimize staffing, inventory, and rider allocation during peak times (lunch, dinner) and peak days (e.g., weekends). Address restaurants with high non-delivery rates through improved order tracking or rider coordination.
3. **Rider Performance**:
   - **Queries 10, 13, 14, 18**: Reward efficient riders (e.g., bonuses for 5-star ratings) and provide training or route optimization for slower riders to improve delivery speed.
4. **Menu and Marketing Strategies**:
   - **Queries 7, 19**: Promote popular and seasonal dishes (e.g., ice cream in Summer) and tailor menus to city-specific preferences to increase order volume.
5. **Market Expansion**:
   - **Queries 6, 20**: Prioritize marketing efforts (e.g., featured listings) and expansion in high-revenue cities and restaurants to maximize growth.

---

## Conclusion

The Zomato SQL data analysis project provides a robust framework for analyzing customer behavior, restaurant performance, and operational efficiency. The database schema is well-structured, with a minor issue in the `fk_riders` constraint that should be removed. The 20 analytical queries offer actionable insights for improving customer retention, optimizing operations, and driving revenue growth. By implementing the recommended strategies, Zomato can enhance platform performance, improve customer satisfaction, and strengthen its market position.



