CREATE VIEW vw_business_overview AS
SELECT 
    COUNT(DISTINCT o.order_id) AS total_orders,
    SUM(oi.price + oi.freight_value) AS total_revenue,
    AVG(order_total.order_value) AS avg_order_value
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN (
    SELECT order_id, SUM(price + freight_value) AS order_value
    FROM order_items
    GROUP BY order_id
) order_total ON o.order_id = order_total.order_id
WHERE o.order_status = 'delivered'

CREATE VIEW vw_monthly_revenue AS
WITH monthly_revenue AS (
    SELECT 
        YEAR(o.order_purchase_timestamp) * 100 + MONTH(o.order_purchase_timestamp) AS order_month,
        SUM(oi.price + oi.freight_value) AS revenue
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
        AND o.order_purchase_timestamp >= '2017-01-01'
    GROUP BY YEAR(o.order_purchase_timestamp) * 100 + MONTH(o.order_purchase_timestamp)
)
SELECT 
    order_month,
    revenue,
    LAG(revenue) OVER (ORDER BY order_month) AS prev_month_revenue,
    ROUND(
        (revenue - LAG(revenue) OVER (ORDER BY order_month)) 
        / LAG(revenue) OVER (ORDER BY order_month) * 100, 2
    ) AS mom_growth_pct
FROM monthly_revenue

CREATE VIEW vw_category_revenue AS
SELECT 
    p.product_category_name_english AS category,
    SUM(oi.price + oi.freight_value) AS total_revenue,
    COUNT(DISTINCT oi.order_id) AS total_orders
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
JOIN orders o ON oi.order_id = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY p.product_category_name_english

CREATE VIEW vw_customer_rfm AS
WITH reference_date AS (
    SELECT MAX(order_purchase_timestamp) AS max_date
    FROM orders
    WHERE order_status = 'delivered'
),
customer_orders AS (
    SELECT 
        c.customer_unique_id,
        o.order_id,
        o.order_purchase_timestamp,
        oi.price + oi.freight_value AS order_value
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
)
SELECT 
    co.customer_unique_id,
    DATEDIFF(DAY, MAX(co.order_purchase_timestamp), r.max_date) AS recency_days,
    COUNT(DISTINCT co.order_id) AS frequency,
    SUM(co.order_value) AS monetary
FROM customer_orders co
CROSS JOIN reference_date r
GROUP BY co.customer_unique_id, r.max_date

CREATE VIEW vw_customer_ranking AS
WITH customer_spending AS (
    SELECT 
        c.customer_unique_id,
        SUM(oi.price + oi.freight_value) AS monetary
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
)
SELECT 
    customer_unique_id,
    monetary,
    RANK() OVER (ORDER BY monetary DESC) AS spending_rank
FROM customer_spending

CREATE VIEW vw_customer_repeat_rate AS
WITH customer_order_count AS (
    SELECT 
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS total_orders
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
),
customer_type AS (
    SELECT 
        customer_unique_id,
        total_orders,
        CASE 
            WHEN total_orders = 1 THEN 'One-time'
            ELSE 'Repeat'
        END AS customer_type
    FROM customer_order_count
)
SELECT 
    customer_type,
    COUNT(*) AS total_customers,
    CAST(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER () AS DECIMAL(5,2)) AS percentage
FROM customer_type
GROUP BY customer_type

CREATE VIEW vw_delivery_by_state AS
SELECT 
    c.customer_state,
    AVG(DATEDIFF(DAY, o.order_purchase_timestamp, o.order_delivered_customer_date)) AS avg_delivery_days,
    COUNT(DISTINCT o.order_id) AS total_orders
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
    AND o.order_delivered_customer_date IS NOT NULL
GROUP BY c.customer_state
HAVING COUNT(DISTINCT o.order_id) >= 30

CREATE VIEW vw_review_by_category AS
SELECT 
    p.product_category_name_english AS category,
    AVG(CAST(r.review_score AS DECIMAL(3,2))) AS avg_review_score,
    COUNT(DISTINCT r.review_id) AS total_reviews
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
JOIN order_reviews r ON oi.order_id = r.order_id
GROUP BY p.product_category_name_english
HAVING COUNT(DISTINCT r.review_id) >= 30