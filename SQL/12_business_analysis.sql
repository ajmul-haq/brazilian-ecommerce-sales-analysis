
-- ============================================================
-- OLIST E-COMMERCE SQL PROJECT
-- FILE: 04_business_analysis.sql
-- PURPOSE: BUSINESS ANALYSIS & BUSINESS INSIGHTS
-- DATABASE: PostgreSQL
-- ============================================================


-- ============================================================
-- 1. OVERALL BUSINESS KPIs
-- Business Question:
-- What are the overall sales, orders, customers, and products?
-- ============================================================

SELECT
    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(DISTINCT c.customer_unique_id) AS total_customers,
    COUNT(DISTINCT oi.product_id) AS total_products,
    COUNT(DISTINCT oi.seller_id) AS total_sellers,

    ROUND(
        SUM(oi.price)::NUMERIC,
        2
    ) AS total_product_sales,

    ROUND(
        SUM(oi.freight_value)::NUMERIC,
        2
    ) AS total_freight_value,

    ROUND(
        (SUM(oi.price) / NULLIF(COUNT(DISTINCT o.order_id), 0))::NUMERIC,
        2
    ) AS average_order_value

FROM orders o

INNER JOIN customers c
    ON o.customer_id = c.customer_id

INNER JOIN order_items oi
    ON o.order_id = oi.order_id;


-- ============================================================
-- 2. ORDER STATUS ANALYSIS
-- Business Question:
-- What is the distribution of orders by status?
-- ============================================================

SELECT
    order_status,
    COUNT(*) AS total_orders,

    ROUND(
        100.0 * COUNT(*) /
        SUM(COUNT(*)) OVER (),
        2
    ) AS percentage_of_orders

FROM orders

GROUP BY
    order_status

ORDER BY
    total_orders DESC;


-- ============================================================
-- 3. MONTHLY SALES TREND
-- Business Question:
-- How do sales change month by month?
-- ============================================================

SELECT
    DATE_TRUNC(
        'month',
        o.order_purchase_timestamp
    ) AS sales_month,

    COUNT(DISTINCT o.order_id) AS total_orders,

    ROUND(
        SUM(oi.price)::NUMERIC,
        2
    ) AS product_sales,

    ROUND(
        SUM(oi.freight_value)::NUMERIC,
        2
    ) AS freight_value

FROM orders o

INNER JOIN order_items oi
    ON o.order_id = oi.order_id

GROUP BY
    DATE_TRUNC(
        'month',
        o.order_purchase_timestamp
    )

ORDER BY
    sales_month;


-- ============================================================
-- 4. YEARLY SALES PERFORMANCE
-- Business Question:
-- How did sales perform by year?
-- ============================================================

SELECT
    EXTRACT(
        YEAR FROM o.order_purchase_timestamp
    ) AS sales_year,

    COUNT(DISTINCT o.order_id) AS total_orders,

    ROUND(
        SUM(oi.price)::NUMERIC,
        2
    ) AS product_sales,

    ROUND(
        SUM(oi.freight_value)::NUMERIC,
        2
    ) AS freight_value

FROM orders o

INNER JOIN order_items oi
    ON o.order_id = oi.order_id

GROUP BY
    EXTRACT(
        YEAR FROM o.order_purchase_timestamp
    )

ORDER BY
    sales_year;


-- ============================================================
-- 5. TOP PRODUCT CATEGORIES BY SALES
-- Business Question:
-- Which product categories generate the most sales?
-- ============================================================

SELECT
    COALESCE(
        pct.product_category_name_english,
        p.product_category_name
    ) AS product_category,

    COUNT(DISTINCT oi.order_id) AS total_orders,

    COUNT(*) AS items_sold,

    ROUND(
        SUM(oi.price)::NUMERIC,
        2
    ) AS product_sales

FROM order_items oi

INNER JOIN products p
    ON oi.product_id = p.product_id

LEFT JOIN product_category_name_translation pct
    ON p.product_category_name =
       pct.product_category_name

GROUP BY
    COALESCE(
        pct.product_category_name_english,
        p.product_category_name
    )

ORDER BY
    product_sales DESC

LIMIT 20;


-- ============================================================
-- 6. TOP PRODUCT CATEGORIES BY NUMBER OF ORDERS
-- Business Question:
-- Which categories are purchased most frequently?
-- ============================================================

SELECT
    COALESCE(
        pct.product_category_name_english,
        p.product_category_name
    ) AS product_category,

    COUNT(DISTINCT oi.order_id) AS total_orders,

    COUNT(*) AS items_sold

FROM order_items oi

INNER JOIN products p
    ON oi.product_id = p.product_id

LEFT JOIN product_category_name_translation pct
    ON p.product_category_name =
       pct.product_category_name

GROUP BY
    COALESCE(
        pct.product_category_name_english,
        p.product_category_name
    )

ORDER BY
    total_orders DESC

LIMIT 20;


-- ============================================================
-- 7. SALES BY CUSTOMER STATE
-- Business Question:
-- Which Brazilian states generate the most sales?
-- ============================================================

SELECT
    c.customer_state,

    COUNT(DISTINCT o.order_id) AS total_orders,

    COUNT(DISTINCT c.customer_unique_id) AS unique_customers,

    ROUND(
        SUM(oi.price)::NUMERIC,
        2
    ) AS product_sales

FROM orders o

INNER JOIN customers c
    ON o.customer_id = c.customer_id

INNER JOIN order_items oi
    ON o.order_id = oi.order_id

GROUP BY
    c.customer_state

ORDER BY
    product_sales DESC;


-- ============================================================
-- 8. CUSTOMER COUNT BY STATE
-- Business Question:
-- Where are Olist customers located?
-- ============================================================

SELECT
    customer_state,

    COUNT(DISTINCT customer_unique_id) AS unique_customers

FROM customers

GROUP BY
    customer_state

ORDER BY
    unique_customers DESC;


-- ============================================================
-- 9. TOP SELLERS BY SALES
-- Business Question:
-- Which sellers generate the highest sales?
-- ============================================================

SELECT
    s.seller_id,

    s.seller_state,

    COUNT(DISTINCT oi.order_id) AS total_orders,

    COUNT(*) AS items_sold,

    ROUND(
        SUM(oi.price)::NUMERIC,
        2
    ) AS product_sales

FROM sellers s

INNER JOIN order_items oi
    ON s.seller_id = oi.seller_id

GROUP BY
    s.seller_id,
    s.seller_state

ORDER BY
    product_sales DESC

LIMIT 20;


-- ============================================================
-- 10. SALES BY SELLER STATE
-- Business Question:
-- Which states have the strongest seller performance?
-- ============================================================

SELECT
    s.seller_state,

    COUNT(DISTINCT s.seller_id) AS total_sellers,

    COUNT(DISTINCT oi.order_id) AS total_orders,

    ROUND(
        SUM(oi.price)::NUMERIC,
        2
    ) AS product_sales

FROM sellers s

INNER JOIN order_items oi
    ON s.seller_id = oi.seller_id

GROUP BY
    s.seller_state

ORDER BY
    product_sales DESC;


-- ============================================================
-- 11. PAYMENT METHOD ANALYSIS
-- Business Question:
-- Which payment methods are most popular?
-- ============================================================

SELECT
    payment_type,

    COUNT(*) AS payment_records,

    COUNT(DISTINCT order_id) AS unique_orders,

    ROUND(
        SUM(payment_value)::NUMERIC,
        2
    ) AS total_payment_value,

    ROUND(
        AVG(payment_value)::NUMERIC,
        2
    ) AS average_payment_value

FROM order_payments

GROUP BY
    payment_type

ORDER BY
    total_payment_value DESC;


-- ============================================================
-- 12. PAYMENT INSTALLMENT ANALYSIS
-- Business Question:
-- How do customers use installment payments?
-- ============================================================

SELECT
    payment_installments,

    COUNT(DISTINCT order_id) AS total_orders,

    ROUND(
        SUM(payment_value)::NUMERIC,
        2
    ) AS total_payment_value

FROM order_payments

GROUP BY
    payment_installments

ORDER BY
    payment_installments;


-- ============================================================
-- 13. CUSTOMER PURCHASE FREQUENCY
-- Business Question:
-- How many customers are one-time vs repeat buyers?
-- ============================================================

WITH customer_orders AS (

    SELECT
        c.customer_unique_id,

        COUNT(DISTINCT o.order_id) AS order_count

    FROM customers c

    INNER JOIN orders o
        ON c.customer_id = o.customer_id

    GROUP BY
        c.customer_unique_id
)

SELECT

    CASE
        WHEN order_count = 1
            THEN 'One-time customer'
        WHEN order_count > 1
            THEN 'Repeat customer'
    END AS customer_type,

    COUNT(*) AS customers,

    ROUND(
        100.0 * COUNT(*) /
        SUM(COUNT(*)) OVER (),
        2
    ) AS percentage

FROM customer_orders

GROUP BY
    CASE
        WHEN order_count = 1
            THEN 'One-time customer'
        WHEN order_count > 1
            THEN 'Repeat customer'
    END

ORDER BY
    customers DESC;


-- ============================================================
-- 14. TOP CUSTOMERS BY SPENDING
-- Business Question:
-- Which customers have spent the most?
-- ============================================================

SELECT
    c.customer_unique_id,

    COUNT(DISTINCT o.order_id) AS total_orders,

    ROUND(
        SUM(oi.price)::NUMERIC,
        2
    ) AS total_spent

FROM customers c

INNER JOIN orders o
    ON c.customer_id = o.customer_id

INNER JOIN order_items oi
    ON o.order_id = oi.order_id

GROUP BY
    c.customer_unique_id

ORDER BY
    total_spent DESC

LIMIT 20;


-- ============================================================
-- 15. AVERAGE CUSTOMER SPENDING
-- Business Question:
-- What is the average amount spent per customer?
-- ============================================================

WITH customer_spending AS (

    SELECT
        c.customer_unique_id,

        SUM(oi.price) AS total_spent

    FROM customers c

    INNER JOIN orders o
        ON c.customer_id = o.customer_id

    INNER JOIN order_items oi
        ON o.order_id = oi.order_id

    GROUP BY
        c.customer_unique_id
)

SELECT

    COUNT(*) AS total_customers,

    ROUND(
        AVG(total_spent)::NUMERIC,
        2
    ) AS average_customer_spending,

    ROUND(
        MIN(total_spent)::NUMERIC,
        2
    ) AS minimum_customer_spending,

    ROUND(
        MAX(total_spent)::NUMERIC,
        2
    ) AS maximum_customer_spending

FROM customer_spending;


-- ============================================================
-- 16. DELIVERY TIME ANALYSIS
-- Business Question:
-- How long does it take to deliver an order?
-- ============================================================

SELECT

    COUNT(*) AS delivered_orders,

    ROUND(
        AVG(
            EXTRACT(
                EPOCH FROM
                (
                    order_delivered_customer_date
                    - order_purchase_timestamp
                )
            ) / 86400
        )::NUMERIC,
        2
    ) AS average_delivery_days,

    ROUND(
        MIN(
            EXTRACT(
                EPOCH FROM
                (
                    order_delivered_customer_date
                    - order_purchase_timestamp
                )
            ) / 86400
        )::NUMERIC,
        2
    ) AS minimum_delivery_days,

    ROUND(
        MAX(
            EXTRACT(
                EPOCH FROM
                (
                    order_delivered_customer_date
                    - order_purchase_timestamp
                )
            ) / 86400
        )::NUMERIC,
        2
    ) AS maximum_delivery_days

FROM orders

WHERE
    order_delivered_customer_date IS NOT NULL

    AND order_purchase_timestamp IS NOT NULL;


-- ============================================================
-- 17. DELIVERY PERFORMANCE BY CUSTOMER STATE
-- Business Question:
-- Which customer states have longer delivery times?
-- ============================================================

SELECT
    c.customer_state,

    COUNT(DISTINCT o.order_id) AS delivered_orders,

    ROUND(
        AVG(
            EXTRACT(
                EPOCH FROM
                (
                    o.order_delivered_customer_date
                    - o.order_purchase_timestamp
                )
            ) / 86400
        )::NUMERIC,
        2
    ) AS average_delivery_days

FROM orders o

INNER JOIN customers c
    ON o.customer_id = c.customer_id

WHERE
    o.order_delivered_customer_date IS NOT NULL

GROUP BY
    c.customer_state

ORDER BY
    average_delivery_days DESC;


-- ============================================================
-- 18. ESTIMATED VS ACTUAL DELIVERY
-- Business Question:
-- How often were orders delivered late?
-- ============================================================

SELECT

    COUNT(*) AS delivered_orders,

    COUNT(*) FILTER (
        WHERE order_delivered_customer_date
              > order_estimated_delivery_date
    ) AS late_orders,

    COUNT(*) FILTER (
        WHERE order_delivered_customer_date
              <= order_estimated_delivery_date
    ) AS on_time_orders,

    ROUND(
        100.0 *
        COUNT(*) FILTER (
            WHERE order_delivered_customer_date
                  > order_estimated_delivery_date
        )
        / NULLIF(COUNT(*), 0),
        2
    ) AS late_delivery_percentage

FROM orders

WHERE
    order_delivered_customer_date IS NOT NULL

    AND order_estimated_delivery_date IS NOT NULL;


-- ============================================================
-- 19. REVIEW SCORE DISTRIBUTION
-- Business Question:
-- How satisfied are customers?
-- ============================================================

SELECT
    review_score,

    COUNT(*) AS total_reviews,

    ROUND(
        100.0 * COUNT(*) /
        SUM(COUNT(*)) OVER (),
        2
    ) AS percentage

FROM order_reviews

GROUP BY
    review_score

ORDER BY
    review_score;


-- ============================================================
-- 20. AVERAGE REVIEW SCORE
-- Business Question:
-- What is the overall customer satisfaction score?
-- ============================================================

SELECT

    COUNT(*) AS total_reviews,

    ROUND(
        AVG(review_score)::NUMERIC,
        2
    ) AS average_review_score

FROM order_reviews;


-- ============================================================
-- 21. PRODUCT CATEGORY + REVIEW SCORE
-- Business Question:
-- Which categories receive the best/worst reviews?
-- ============================================================

SELECT
    COALESCE(
        pct.product_category_name_english,
        p.product_category_name
    ) AS product_category,

    COUNT(DISTINCT r.review_id) AS total_reviews,

    ROUND(
        AVG(r.review_score)::NUMERIC,
        2
    ) AS average_review_score

FROM order_reviews r

INNER JOIN order_items oi
    ON r.order_id = oi.order_id

INNER JOIN products p
    ON oi.product_id = p.product_id

LEFT JOIN product_category_name_translation pct
    ON p.product_category_name =
       pct.product_category_name

GROUP BY
    COALESCE(
        pct.product_category_name_english,
        p.product_category_name
    )

HAVING
    COUNT(DISTINCT r.review_id) >= 50

ORDER BY
    average_review_score DESC;


-- ============================================================
-- 22. PRODUCT PERFORMANCE
-- Business Question:
-- Which products sell the most units and generate the most revenue?
-- ============================================================

SELECT
    p.product_id,

    COALESCE(
        pct.product_category_name_english,
        p.product_category_name
    ) AS product_category,

    COUNT(*) AS units_sold,

    COUNT(DISTINCT oi.order_id) AS orders,

    ROUND(
        SUM(oi.price)::NUMERIC,
        2
    ) AS product_sales

FROM products p

INNER JOIN order_items oi
    ON p.product_id = oi.product_id

LEFT JOIN product_category_name_translation pct
    ON p.product_category_name =
       pct.product_category_name

GROUP BY
    p.product_id,
    COALESCE(
        pct.product_category_name_english,
        p.product_category_name
    )

ORDER BY
    product_sales DESC

LIMIT 20;


-- ============================================================
-- 23. WEEKDAY ORDER ANALYSIS
-- Business Question:
-- Which days of the week receive the most orders?
-- ============================================================

SELECT
    TO_CHAR(
        order_purchase_timestamp,
        'Day'
    ) AS weekday,

    COUNT(*) AS total_orders

FROM orders

GROUP BY
    EXTRACT(
        ISODOW FROM order_purchase_timestamp
    ),

    TO_CHAR(
        order_purchase_timestamp,
        'Day'
    )

ORDER BY
    EXTRACT(
        ISODOW FROM order_purchase_timestamp
    );


-- ============================================================
-- 24. MONTHLY AVERAGE ORDER VALUE
-- Business Question:
-- How does average order value change over time?
-- ============================================================

SELECT
    DATE_TRUNC(
        'month',
        o.order_purchase_timestamp
    ) AS sales_month,

    COUNT(DISTINCT o.order_id) AS total_orders,

    ROUND(
        SUM(oi.price)::NUMERIC,
        2
    ) AS total_sales,

    ROUND(
        (
            SUM(oi.price)
            /
            NULLIF(COUNT(DISTINCT o.order_id), 0)
        )::NUMERIC,
        2
    ) AS average_order_value

FROM orders o

INNER JOIN order_items oi
    ON o.order_id = oi.order_id

GROUP BY
    DATE_TRUNC(
        'month',
        o.order_purchase_timestamp
    )

ORDER BY
    sales_month;


-- ============================================================
-- 25. SALES BY PAYMENT TYPE
-- Business Question:
-- How much sales value is associated with each payment method?
-- ============================================================

SELECT
    payment_type,

    COUNT(DISTINCT order_id) AS total_orders,

    ROUND(
        SUM(payment_value)::NUMERIC,
        2
    ) AS total_payment_value,

    ROUND(
        AVG(payment_value)::NUMERIC,
        2
    ) AS average_payment_value

FROM order_payments

GROUP BY
    payment_type

ORDER BY
    total_payment_value DESC;


-- ============================================================
-- 26. FINAL BUSINESS SUMMARY
-- Business Question:
-- What are the key headline metrics for the project?
-- ============================================================

SELECT

    (SELECT COUNT(DISTINCT order_id)
     FROM orders)
     AS total_orders,

    (SELECT COUNT(DISTINCT customer_unique_id)
     FROM customers)
     AS total_customers,

    (SELECT COUNT(DISTINCT product_id)
     FROM products)
     AS total_products,

    (SELECT COUNT(DISTINCT seller_id)
     FROM sellers)
     AS total_sellers,

    (SELECT ROUND(SUM(price)::NUMERIC, 2)
     FROM order_items)
     AS total_product_sales,

    (SELECT ROUND(SUM(freight_value)::NUMERIC, 2)
     FROM order_items)
     AS total_freight_value;
