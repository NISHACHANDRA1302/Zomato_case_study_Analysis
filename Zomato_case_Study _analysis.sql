create database zomato;
use zomato;

-- Users table
CREATE TABLE users (
    user_id INT PRIMARY KEY,
    name VARCHAR(100),
    email VARCHAR(100),
    password VARCHAR(100)
);

INSERT INTO users VALUES
(1, 'Amit', 'amit@gmail.com', '1234'),
(2, 'Ravi', 'ravi@gmail.com', '1234'),
(3, 'Sneha', 'sneha@gmail.com', '1234'),
(4, 'Priya', 'priya@gmail.com', '1234'),
(5, 'Kiran', 'kiran@gmail.com', '1234');


-- RESTAURANTS TABLE
CREATE TABLE restaurants (
    r_id INT PRIMARY KEY,
    r_name VARCHAR(100),
    cuisine VARCHAR(100)
);

INSERT INTO restaurants VALUES
(1, 'Spice Hub', 'Indian'),
(2, 'Pizza Palace', 'Italian'),
(3, 'Dragon House', 'Chinese');


-- FOOD TABLE
CREATE TABLE food (
    f_id INT PRIMARY KEY,
    f_name VARCHAR(100),
    type VARCHAR(20)
);

INSERT INTO food VALUES
(1, 'Paneer Butter Masala', 'Veg'),
(2, 'Chicken Biryani', 'Non-veg'),
(3, 'Margherita Pizza', 'Veg'),
(4, 'Veg Noodles', 'Veg'),
(5, 'Chicken Noodles', 'Non-veg');


-- MENU TABLE
CREATE TABLE menu (
    menu_id INT PRIMARY KEY,
    r_id INT,
    f_id INT,
    price DECIMAL(10,2),
    FOREIGN KEY (r_id) REFERENCES restaurants(r_id),
    FOREIGN KEY (f_id) REFERENCES food(f_id)
);

INSERT INTO menu VALUES
(1, 1, 1, 250),
(2, 1, 2, 300),
(3, 2, 3, 200),
(4, 3, 4, 180),
(5, 3, 5, 220);


-- DELIVERY PARTNER TABLE
CREATE TABLE delivery_partner (
    partner_id INT PRIMARY KEY,
    partner_name VARCHAR(100)
);

INSERT INTO delivery_partner VALUES
(1, 'Rahul'),
(2, 'Arjun'),
(3, 'Manoj');


-- ORDERS TABLE
CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    user_id INT,
    r_id INT,
    amount DECIMAL(10,2),
    date DATE,
    partner_id INT,
    delivery_time INT,
    delivery_rating INT,
    restaurant_rating INT,
    
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (r_id) REFERENCES restaurants(r_id),
    FOREIGN KEY (partner_id) REFERENCES delivery_partner(partner_id)
);

INSERT INTO orders VALUES
(1, 1, 1, 550, '2023-06-10', 1, 30, 5, 4),
(2, 2, 2, 200, '2023-06-12', 2, 25, 4, 5),
(3, 1, 3, 400, '2023-07-05', 3, 35, 5, 4),
(4, 3, 1, 250, '2023-07-10', 1, 20, 3, 4),
(5, 2, 3, 220, '2023-08-01', 2, 40, 4, 3);


-- ORDER DETAILS TABLE
CREATE TABLE order_details (
    id INT PRIMARY KEY,
    order_id INT,
    f_id INT,
    
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (f_id) REFERENCES food(f_id)
);

INSERT INTO order_details VALUES
(1, 1, 1),
(2, 1, 2),
(3, 2, 3),
(4, 3, 4),
(5, 3, 5),
(6, 4, 1),
(7, 5, 5);

select * from delivery_partner;
select * from food;
select * from menu;
select * from order_details;
select * from orders;
select * from restaurants;
select * from users;


-- 1. Find customers who have never ordered
SELECT u.user_id, u.name
FROM users u
LEFT JOIN orders o
  ON u.user_id = o.user_id
WHERE o.order_id IS NULL;

-- 2.Average Price per Dish
SELECT f.f_name,
       AVG(m.price) AS avg_price
FROM menu m
JOIN food f
  ON m.f_id = f.f_id
GROUP BY f.f_name;

-- 3. Find the Top Restaurant in Terms of Number of Orders for a Given Month
 -- Example: Find Top Restaurant for July 2023
 SELECT r.r_name,
       COUNT(o.order_id) AS total_orders
FROM orders o
JOIN restaurants r
  ON o.r_id = r.r_id
WHERE MONTH(o.date) = 7
  AND YEAR(o.date) = 2023
GROUP BY r.r_name
ORDER BY total_orders DESC
LIMIT 1;

-- 4.Restaurants with Monthly Sales Greater Than X
-- Example: Find Restaurants with Monthly Sales > 500
SELECT r.r_name,
       YEAR(o.date) AS year,
       MONTH(o.date) AS month,
       SUM(o.amount) AS total_sales
FROM orders o
JOIN restaurants r
  ON o.r_id = r.r_id
GROUP BY r.r_name, YEAR(o.date), MONTH(o.date)
HAVING SUM(o.amount) > 500;

-- 5.Show All Orders with Order Details for a Particular Customer in a Given Date Range
/**Example
Customer = user_id = 1
Date range = '2023-06-01' to '2023-07-31' **/
SELECT 
    o.order_id,
    o.date,
    r.r_name,
    f.f_name,
    m.price,
    o.amount
FROM orders o
JOIN restaurants r
    ON o.r_id = r.r_id
JOIN order_details od
    ON o.order_id = od.order_id
JOIN food f
    ON od.f_id = f.f_id
JOIN menu m
    ON m.f_id = f.f_id AND m.r_id = o.r_id
WHERE o.user_id = 1
  AND o.date BETWEEN '2023-06-01' AND '2023-07-31'
ORDER BY o.date;


-- 6. Find Restaurants with Maximum Repeated Customers

WITH repeat_customers AS (
    SELECT 
        r_id,
        user_id
    FROM orders
    GROUP BY r_id, user_id
    HAVING COUNT(order_id) > 1
)

SELECT 
    r.r_id,
    r.r_name,
    COUNT(rc.user_id) AS repeat_customer_count
FROM restaurants r
LEFT JOIN repeat_customers rc
    ON r.r_id = rc.r_id
GROUP BY r.r_id, r.r_name
ORDER BY repeat_customer_count DESC;

-- 7.Month Over Month (MoM) Revenue Growth of Swiggy
WITH monthly_revenue AS (
    SELECT 
        DATE_FORMAT(date, '%Y-%m') AS month,
        SUM(amount) AS total_revenue
    FROM orders
    GROUP BY DATE_FORMAT(date, '%Y-%m')
)

SELECT 
    month,
    total_revenue,
    LAG(total_revenue) OVER (ORDER BY month) AS previous_month_revenue,
    
    ROUND(
        ((total_revenue - LAG(total_revenue) OVER (ORDER BY month)) 
        / LAG(total_revenue) OVER (ORDER BY month)) * 100
    , 2) AS mom_growth_percentage

FROM monthly_revenue;

-- 8. Customer – Favorite Food
/**Favorite food =
The food item that a customer ordered the most number of times**/
WITH customer_food_count AS (
    SELECT 
        o.user_id,
        od.f_id,
        f.f_name,
        COUNT(*) AS order_count
    FROM orders o
    JOIN order_details od 
        ON o.order_id = od.order_id
    JOIN food f 
        ON od.f_id = f.f_id
    GROUP BY o.user_id, od.f_id, f.f_name
),

ranked_food AS (
    SELECT *,
           RANK() OVER (PARTITION BY user_id ORDER BY order_count DESC) AS rk
    FROM customer_food_count
)

SELECT 
    user_id,
    f_name AS favorite_food,
    order_count
FROM ranked_food
WHERE rk = 1;

-- 9.Most Loyal Customers for All Restaurants
WITH customer_order_count AS (
    SELECT 
        r_id,
        user_id,
        COUNT(order_id) AS total_orders
    FROM orders
    GROUP BY r_id, user_id
),

ranked_customers AS (
    SELECT *,
           RANK() OVER (PARTITION BY r_id ORDER BY total_orders DESC) AS rk
    FROM customer_order_count
)

SELECT 
    r_id,
    user_id,
    total_orders
FROM ranked_customers
WHERE rk = 1;

-- 10. Most Paired Products : Which two food items are most frequently ordered together?
SELECT 
    f1.f_name AS product_1,
    f2.f_name AS product_2,
    COUNT(*) AS pair_count
FROM order_details od1
JOIN order_details od2 
    ON od1.order_id = od2.order_id
    AND od1.f_id < od2.f_id   -- avoids duplicate pairs
JOIN food f1 
    ON od1.f_id = f1.f_id
JOIN food f2 
    ON od2.f_id = f2.f_id
GROUP BY f1.f_name, f2.f_name
ORDER BY pair_count DESC;


-- 11. Month Over Month Revenue Growth of a Single Restaurant
-- What is the month-over-month revenue growth for each individual restaurant?

WITH monthly_revenue AS (
    SELECT 
        r_id,
        DATE_FORMAT(date, '%Y-%m') AS month,
        SUM(amount) AS total_revenue
    FROM orders
    GROUP BY r_id, DATE_FORMAT(date, '%Y-%m')
)

SELECT 
    r_id,
    month,
    total_revenue,
    LAG(total_revenue) OVER (PARTITION BY r_id ORDER BY month) AS previous_month_revenue,

    ROUND(
        (
            (total_revenue - LAG(total_revenue) OVER (PARTITION BY r_id ORDER BY month))
            /
            LAG(total_revenue) OVER (PARTITION BY r_id ORDER BY month)
        ) * 100
    , 2) AS mom_growth_percentage

FROM monthly_revenue
ORDER BY r_id, month;


-- 11.Top 3 Restaurants by Revenue Per Month
-- For each month, find the top 3 restaurants based on revenue.
WITH monthly_revenue AS (
    SELECT 
        r_id,
        DATE_FORMAT(date, '%Y-%m') AS month,
        SUM(amount) AS total_revenue
    FROM orders
    GROUP BY r_id, DATE_FORMAT(date, '%Y-%m')
),

ranked_restaurants AS (
    SELECT *,
           RANK() OVER (PARTITION BY month ORDER BY total_revenue DESC) AS rk
    FROM monthly_revenue
)

SELECT 
    month,
    r_id,
    total_revenue
FROM ranked_restaurants
WHERE rk <= 3
ORDER BY month, rk;


-- 12. Customer Retention Rate (Month Over Month)
-- What percentage of customers who ordered last month also ordered this month?

WITH monthly_customers AS (
    SELECT DISTINCT
        DATE_FORMAT(date, '%Y-%m') AS month,
        user_id
    FROM orders
),

retention_data AS (
    SELECT 
        curr.month,
        COUNT(DISTINCT curr.user_id) AS current_customers,
        COUNT(DISTINCT prev.user_id) AS retained_customers
    FROM monthly_customers curr
    LEFT JOIN monthly_customers prev
        ON curr.user_id = prev.user_id
        AND prev.month = DATE_FORMAT(
                DATE_SUB(STR_TO_DATE(CONCAT(curr.month,'-01'),'%Y-%m-%d'), INTERVAL 1 MONTH),
                '%Y-%m'
            )
    GROUP BY curr.month
)

SELECT 
    month,
    current_customers,
    retained_customers,
    ROUND((retained_customers / current_customers) * 100, 2) AS retention_rate_percentage
FROM retention_data
ORDER BY month;


-- 13. Find the second highest revenue generating restaurant.
WITH revenue_data AS (
    SELECT 
        r_id,
        SUM(amount) AS total_revenue
    FROM orders
    GROUP BY r_id
)

SELECT r_id, total_revenue
FROM (
    SELECT *,
           DENSE_RANK() OVER (ORDER BY total_revenue DESC) AS rk
    FROM revenue_data
) t
WHERE rk = 2;


-- 14.Find customers who spent more than the average customer spending. 
SELECT user_id, SUM(amount) AS total_spent
FROM orders
GROUP BY user_id
HAVING SUM(amount) > (
    SELECT AVG(customer_total)
    FROM (
        SELECT SUM(amount) AS customer_total
        FROM orders
        GROUP BY user_id
    ) t
);


-- 15. Find percentage contribution of each restaurant to total company revenue.
WITH restaurant_revenue AS (
    SELECT 
        r_id,
        SUM(amount) AS revenue
    FROM orders
    GROUP BY r_id
),

total_revenue AS (
    SELECT SUM(revenue) AS company_total
    FROM restaurant_revenue
)

SELECT 
    r.r_id,
    r.r_name,
    rr.revenue,
    ROUND((rr.revenue / tr.company_total) * 100, 2) AS revenue_percentage
FROM restaurant_revenue rr
JOIN total_revenue tr
JOIN restaurants r 
    ON rr.r_id = r.r_id;
    
    
-- 16. Find peak ordering day of the week.
SELECT 
    DAYNAME(date) AS day_name,
    COUNT(order_id) AS total_orders
FROM orders
GROUP BY DAYNAME(date)
ORDER BY total_orders DESC
LIMIT 1;


/** 17. Zomato wants a combined report showing:
Restaurants that generated revenue more than 500
Customers who spent more than 500
Show them in a single result with a column that tells whether it is a Restaurant or Customer. **/
SELECT 
    'Restaurant' AS type,
    r_id AS id,
    SUM(amount) AS total_amount
FROM orders
GROUP BY r_id
HAVING SUM(amount) > 500

UNION

SELECT 
    'Customer' AS type,
    user_id AS id,
    SUM(amount) AS total_amount
FROM orders
GROUP BY user_id
HAVING SUM(amount) > 500;



-- 18. Customers Who Ordered in June OR July (Without Duplicates) 
SELECT user_id
FROM orders
WHERE DATE_FORMAT(date, '%Y-%m') = '2023-06'

UNION

SELECT user_id
FROM orders
WHERE DATE_FORMAT(date, '%Y-%m') = '2023-07';

-- 19. Restaurants That Had Orders Above 300 OR Orders Below 100 
SELECT DISTINCT r_id
FROM orders
WHERE amount > 300

UNION

SELECT DISTINCT r_id
FROM orders
WHERE amount < 100;


-- 20. Top 2 Revenue Restaurants from Two Different Months
(SELECT 
    'June' AS month,
    r_id,
    SUM(amount) AS revenue
 FROM orders
 WHERE DATE_FORMAT(date, '%Y-%m') = '2023-06'
 GROUP BY r_id
 ORDER BY revenue DESC
 LIMIT 2)

UNION ALL

(SELECT 
    'July' AS month,
    r_id,
    SUM(amount) AS revenue
 FROM orders
 WHERE DATE_FORMAT(date, '%Y-%m') = '2023-07'
 GROUP BY r_id
 ORDER BY revenue DESC
 LIMIT 2);
 
 

