-- ============================================================
-- STEP 1: CHECK TABLE ROW COUNTS
-- ============================================================

SELECT 'customers' AS table_name, COUNT(*) AS row_count
FROM customers

UNION ALL

SELECT 'orders', COUNT(*)
FROM orders

UNION ALL

SELECT 'order_items', COUNT(*)
FROM order_items

UNION ALL

SELECT 'products', COUNT(*)
FROM products

UNION ALL

SELECT 'sellers', COUNT(*)
FROM sellers

UNION ALL

SELECT 'order_payments', COUNT(*)
FROM order_payments

UNION ALL

SELECT 'order_reviews', COUNT(*)
FROM order_reviews

UNION ALL

SELECT 'geolocation', COUNT(*)
FROM geolocation

UNION ALL

SELECT 'product_category_name_translation', COUNT(*)
FROM product_category_name_translation;

-- ============================================================
-- STEP 2: CUSTOMERS + ORDERS
-- ============================================================

SELECT
    c.customer_id,
    c.customer_unique_id,
    c.customer_city,
    c.customer_state,
    o.order_id,
    o.order_status,
    o.order_purchase_timestamp
FROM customers c
INNER JOIN orders o
    ON c.customer_id = o.customer_id
LIMIT 100;

-- ============================================================
-- STEP 3: ORDERS + ORDER ITEMS
-- ============================================================

SELECT
    o.order_id,
    o.order_status,
    oi.order_item_id,
    oi.product_id,
    oi.seller_id,
    oi.price,
    oi.freight_value
FROM orders o
INNER JOIN order_items oi
    ON o.order_id = oi.order_id
LIMIT 100;

-- ============================================================
-- STEP 4: ORDERS + PAYMENTS
-- ============================================================

SELECT
    o.order_id,
    o.order_status,
    op.payment_type,
    op.payment_installments,
    op.payment_value
FROM orders o
INNER JOIN order_payments op
    ON o.order_id = op.order_id
LIMIT 100;

-- ============================================================
-- STEP 5: ORDERS + REVIEWS
-- ============================================================

SELECT
    o.order_id,
    o.order_status,
    r.review_id,
    r.review_score
FROM orders o
LEFT JOIN order_reviews r
    ON o.order_id = r.order_id
LIMIT 100;

-- ============================================================
-- STEP 6: ORDER ITEMS + PRODUCTS
-- ============================================================

SELECT
    oi.order_id,
    oi.product_id,
    oi.price,
    p.product_category_name,
    p.product_weight_g
FROM order_items oi
INNER JOIN products p
    ON oi.product_id = p.product_id
LIMIT 100;

-- ============================================================
-- STEP 7: ORDER ITEMS + SELLERS
-- ============================================================

SELECT
    oi.order_id,
    oi.product_id,
    oi.seller_id,
    oi.price,
    s.seller_city,
    s.seller_state
FROM order_items oi
INNER JOIN sellers s
    ON oi.seller_id = s.seller_id
LIMIT 100;

-- ============================================================
-- STEP 8: PRODUCTS + ENGLISH CATEGORY NAMES
-- ============================================================

SELECT
    p.product_id,
    p.product_category_name AS category_portuguese,
    pct.product_category_name_english AS category_english
FROM products p
LEFT JOIN product_category_name_translation pct
    ON p.product_category_name =
       pct.product_category_name
LIMIT 100;

-- ============================================================
-- STEP 9: CREATE SAFE GEOLOCATION DATA
-- ONE ROW PER ZIP CODE PREFIX
-- ============================================================

DROP VIEW IF EXISTS geo_zip;

CREATE TEMP VIEW geo_zip AS

SELECT
    geolocation_zip_code_prefix::TEXT AS zip_code,
    MAX(geolocation_city) AS city,
    MAX(geolocation_state) AS state,
    AVG(geolocation_lat) AS latitude,
    AVG(geolocation_lng) AS longitude
FROM geolocation

GROUP BY
    geolocation_zip_code_prefix::TEXT;

-- ============================================================
-- STEP 9B: TEST SAFE GEOLOCATION VIEW
-- ============================================================

SELECT *
FROM geo_zip
LIMIT 100;

-- ============================================================
-- STEP 10: CUSTOMERS + SAFE GEOLOCATION
-- ============================================================

SELECT
    c.customer_id,
    c.customer_city,
    c.customer_state,
    c.customer_zip_code_prefix,
    g.city AS geo_city,
    g.state AS geo_state,
    g.latitude,
    g.longitude
FROM customers c
LEFT JOIN geo_zip g
    ON c.customer_zip_code_prefix::TEXT =
       g.zip_code
LIMIT 100;

-- ============================================================
-- STEP 11: SELLERS + SAFE GEOLOCATION
-- ============================================================

SELECT
    s.seller_id,
    s.seller_city,
    s.seller_state,
    s.seller_zip_code_prefix,
    g.city AS geo_city,
    g.state AS geo_state,
    g.latitude,
    g.longitude
FROM sellers s
LEFT JOIN geo_zip g
    ON s.seller_zip_code_prefix::TEXT =
       g.zip_code
LIMIT 100;

-- ============================================================
-- STEP 12: CUSTOMERS + ORDERS + ORDER ITEMS
-- ============================================================

SELECT
    c.customer_id,
    c.customer_state,
    o.order_id,
    o.order_status,
    o.order_purchase_timestamp,
    oi.product_id,
    oi.seller_id,
    oi.price,
    oi.freight_value
FROM customers c

INNER JOIN orders o
    ON c.customer_id = o.customer_id

INNER JOIN order_items oi
    ON o.order_id = oi.order_id

LIMIT 100;

-- ============================================================
-- STEP 13: ORDERS + CUSTOMERS + PRODUCTS
-- ============================================================

SELECT
    o.order_id,
    o.order_status,
    c.customer_state,
    oi.product_id,
    p.product_category_name,
    oi.price,
    oi.freight_value
FROM orders o

INNER JOIN customers c
    ON o.customer_id = c.customer_id

INNER JOIN order_items oi
    ON o.order_id = oi.order_id

INNER JOIN products p
    ON oi.product_id = p.product_id

LIMIT 100;

-- ============================================================
-- STEP 14: ORDERS + CUSTOMERS + PRODUCTS + SELLERS
-- ============================================================

SELECT
    o.order_id,
    o.order_status,
    c.customer_state,
    oi.product_id,
    p.product_category_name,
    oi.seller_id,
    s.seller_state,
    oi.price,
    oi.freight_value

FROM orders o

INNER JOIN customers c
    ON o.customer_id = c.customer_id

INNER JOIN order_items oi
    ON o.order_id = oi.order_id

INNER JOIN products p
    ON oi.product_id = p.product_id

INNER JOIN sellers s
    ON oi.seller_id = s.seller_id

LIMIT 100;

-- ============================================================
-- STEP 15: ADD ENGLISH PRODUCT CATEGORY
-- ============================================================

SELECT
    o.order_id,
    o.order_status,
    c.customer_state,
    oi.product_id,

    COALESCE(
        pct.product_category_name_english,
        p.product_category_name
    ) AS product_category,

    oi.seller_id,
    s.seller_state,
    oi.price,
    oi.freight_value

FROM orders o

INNER JOIN customers c
    ON o.customer_id = c.customer_id

INNER JOIN order_items oi
    ON o.order_id = oi.order_id

INNER JOIN products p
    ON oi.product_id = p.product_id

INNER JOIN sellers s
    ON oi.seller_id = s.seller_id

LEFT JOIN product_category_name_translation pct
    ON p.product_category_name =
       pct.product_category_name

LIMIT 100;

-- ============================================================
-- STEP 16: AGGREGATE PAYMENTS BY ORDER
-- ============================================================

SELECT
    order_id,
    SUM(payment_value) AS total_payment_value
FROM order_payments
GROUP BY order_id
LIMIT 100;

-- ============================================================
-- STEP 17: MAIN BUSINESS JOIN
-- ORDERS + CUSTOMERS + ITEMS + PRODUCTS + SELLERS
-- ============================================================

SELECT
    o.order_id,
    o.order_status,
    o.order_purchase_timestamp,

    c.customer_state,

    oi.product_id,
    oi.seller_id,

    COALESCE(
        pct.product_category_name_english,
        p.product_category_name
    ) AS product_category,

    s.seller_state,

    oi.price,
    oi.freight_value

FROM orders o

INNER JOIN customers c
    ON o.customer_id = c.customer_id

INNER JOIN order_items oi
    ON o.order_id = oi.order_id

INNER JOIN products p
    ON oi.product_id = p.product_id

INNER JOIN sellers s
    ON oi.seller_id = s.seller_id

LEFT JOIN product_category_name_translation pct
    ON p.product_category_name =
       pct.product_category_name

LIMIT 100;

-- ============================================================
-- STEP 18: SALES BY PRODUCT CATEGORY
-- ============================================================

SELECT
    COALESCE(
        pct.product_category_name_english,
        p.product_category_name
    ) AS product_category,

    COUNT(DISTINCT oi.order_id) AS total_orders,

    SUM(oi.price) AS product_sales,

    SUM(oi.freight_value) AS freight_sales

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
    product_sales DESC;

-- ============================================================
-- STEP 19: SALES BY CUSTOMER STATE
-- ============================================================

SELECT
    c.customer_state,

    COUNT(DISTINCT o.order_id) AS total_orders,

    SUM(oi.price) AS product_sales,

    SUM(oi.freight_value) AS freight_sales

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
-- STEP 20: SALES BY SELLER STATE
-- ============================================================

SELECT
    s.seller_state,

    COUNT(DISTINCT oi.order_id) AS total_orders,

    SUM(oi.price) AS product_sales,

    SUM(oi.freight_value) AS freight_sales

FROM order_items oi

INNER JOIN sellers s
    ON oi.seller_id = s.seller_id

GROUP BY
    s.seller_state

ORDER BY
    product_sales DESC;

-- ============================================================
-- STEP 21: PAYMENT ANALYSIS
-- ============================================================

SELECT
    payment_type,

    COUNT(*) AS payment_records,

    COUNT(DISTINCT order_id) AS unique_orders,

    SUM(payment_value) AS total_payment_value,

    AVG(payment_value) AS average_payment_value

FROM order_payments

GROUP BY
    payment_type

ORDER BY
    total_payment_value DESC;

-- ============================================================
-- STEP 22: DELIVERY TIME ANALYSIS
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
        ),
        2
    ) AS average_delivery_days

FROM orders

WHERE
    order_delivered_customer_date IS NOT NULL
    AND order_purchase_timestamp IS NOT NULL;

-- ============================================================
-- STEP 23: CUSTOMER PURCHASE BEHAVIOR
-- ============================================================

SELECT
    c.customer_unique_id,

    COUNT(DISTINCT o.order_id) AS total_orders,

    SUM(oi.price) AS total_spent

FROM customers c

INNER JOIN orders o
    ON c.customer_id = o.customer_id

INNER JOIN order_items oi
    ON o.order_id = oi.order_id

GROUP BY
    c.customer_unique_id

ORDER BY
    total_spent DESC

LIMIT 100;

-- ============================================================
-- STEP 24: REPEAT CUSTOMER ANALYSIS
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

    COUNT(*) AS total_customers,

    COUNT(*) FILTER (
        WHERE order_count = 1
    ) AS one_time_customers,

    COUNT(*) FILTER (
        WHERE order_count > 1
    ) AS repeat_customers,

    ROUND(
        100.0 *
        COUNT(*) FILTER (
            WHERE order_count > 1
        )
        / NULLIF(COUNT(*), 0),
        2
    ) AS repeat_customer_percentage

FROM customer_orders;

-- ============================================================
-- STEP 25: TOP SELLERS
-- ============================================================

SELECT
    s.seller_id,
    s.seller_state,

    COUNT(DISTINCT oi.order_id) AS total_orders,

    SUM(oi.price) AS product_sales,

    SUM(oi.freight_value) AS freight_sales

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
-- STEP 26: TOP PRODUCTS
-- ============================================================

SELECT
    p.product_id,

    COALESCE(
        pct.product_category_name_english,
        p.product_category_name
    ) AS product_category,

    COUNT(*) AS items_sold,

    SUM(oi.price) AS product_sales

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
-- STEP 27: FINAL SAFE MULTI-TABLE BUSINESS ANALYSIS
-- ============================================================

SELECT
    c.customer_state,

    COALESCE(
        pct.product_category_name_english,
        p.product_category_name
    ) AS product_category,

    s.seller_state,

    COUNT(DISTINCT o.order_id) AS total_orders,

    COUNT(*) AS total_items,

    ROUND(
        SUM(oi.price)::NUMERIC,
        2
    ) AS product_sales,

    ROUND(
        SUM(oi.freight_value)::NUMERIC,
        2
    ) AS freight_sales

FROM orders o

INNER JOIN customers c
    ON o.customer_id = c.customer_id

INNER JOIN order_items oi
    ON o.order_id = oi.order_id

INNER JOIN products p
    ON oi.product_id = p.product_id

INNER JOIN sellers s
    ON oi.seller_id = s.seller_id

LEFT JOIN product_category_name_translation pct
    ON p.product_category_name =
       pct.product_category_name

GROUP BY
    c.customer_state,

    COALESCE(
        pct.product_category_name_english,
        p.product_category_name
    ),

    s.seller_state

ORDER BY
    product_sales DESC

LIMIT 100;

