-- ============================================================
-- 01. REVENUE BY PRODUCT CATEGORY
-- Business Question:
-- Which product categories generate the most revenue?
--
-- Purpose:
-- Identify the categories contributing most to product sales.
--
-- Revenue Definition:
-- Product sales = SUM(order_items.price)
-- ============================================================

SELECT
    COALESCE(
        pct.product_category_name_english,
        p.product_category_name,
        'Unknown'
    ) AS product_category,

    COUNT(DISTINCT oi.order_id) AS total_orders,

    SUM(oi.order_item_id) AS total_items_sold,

    ROUND(
        SUM(oi.price)::NUMERIC,
        2
    ) AS total_product_sales

FROM order_items oi

INNER JOIN products p
    ON oi.product_id = p.product_id

LEFT JOIN product_category_name_translation pct
    ON p.product_category_name =
       pct.product_category_name

GROUP BY
    COALESCE(
        pct.product_category_name_english,
        p.product_category_name,
        'Unknown'
    )

ORDER BY total_product_sales DESC;

-- ============================================================
-- 02. ITEM QUANTITY BY PRODUCT CATEGORY
-- Business Question:
-- Which product categories sell the most items?
--
-- Purpose:
-- Identify categories with the highest sales volume.
--
-- Note:
-- Each row in order_items represents an order line item.
-- ============================================================

SELECT
    COALESCE(
        pct.product_category_name_english,
        p.product_category_name,
        'Unknown'
    ) AS product_category,

    COUNT(*) AS total_items_sold,

    COUNT(DISTINCT oi.order_id) AS total_orders,

    COUNT(DISTINCT oi.product_id) AS distinct_products,

    ROUND(
        SUM(oi.price)::NUMERIC,
        2
    ) AS total_product_sales

FROM order_items oi

INNER JOIN products p
    ON oi.product_id = p.product_id

LEFT JOIN product_category_name_translation pct
    ON p.product_category_name =
       pct.product_category_name

GROUP BY
    COALESCE(
        pct.product_category_name_english,
        p.product_category_name,
        'Unknown'
    )

ORDER BY total_items_sold DESC;

-- ============================================================
-- 03. LOWEST-SELLING PRODUCTS
-- Business Question:
-- Which products have the lowest recorded sales?
--
-- Purpose:
-- Identify products with low sales value and low demand.
--
-- Scope:
-- Products with at least one recorded order item.
-- ============================================================

SELECT
    oi.product_id,

    COALESCE(
        pct.product_category_name_english,
        p.product_category_name,
        'Unknown'
    ) AS product_category,

    COUNT(*) AS total_items_sold,

    COUNT(DISTINCT oi.order_id) AS total_orders,

    ROUND(
        SUM(oi.price)::NUMERIC,
        2
    ) AS total_product_sales

FROM order_items oi

INNER JOIN products p
    ON oi.product_id = p.product_id

LEFT JOIN product_category_name_translation pct
    ON p.product_category_name =
       pct.product_category_name

GROUP BY
    oi.product_id,
    COALESCE(
        pct.product_category_name_english,
        p.product_category_name,
        'Unknown'
    )

ORDER BY
    total_product_sales ASC,
    total_items_sold ASC

LIMIT 20;

-- ============================================================
-- 04. AVERAGE SELLING PRICE BY CATEGORY
-- Business Question:
-- What is the average item selling price in each category?
--
-- Purpose:
-- Compare price levels across product categories.
--
-- Formula:
-- Average Selling Price = AVG(order_items.price)
-- ============================================================

SELECT
    COALESCE(
        pct.product_category_name_english,
        p.product_category_name,
        'Unknown'
    ) AS product_category,

    COUNT(*) AS total_items_sold,

    ROUND(
        AVG(oi.price)::NUMERIC,
        2
    ) AS average_selling_price,

    ROUND(
        MIN(oi.price)::NUMERIC,
        2
    ) AS minimum_selling_price,

    ROUND(
        MAX(oi.price)::NUMERIC,
        2
    ) AS maximum_selling_price,

    ROUND(
        SUM(oi.price)::NUMERIC,
        2
    ) AS total_product_sales

FROM order_items oi

INNER JOIN products p
    ON oi.product_id = p.product_id

LEFT JOIN product_category_name_translation pct
    ON p.product_category_name =
       pct.product_category_name

GROUP BY
    COALESCE(
        pct.product_category_name_english,
        p.product_category_name,
        'Unknown'
    )

ORDER BY average_selling_price DESC;
-- ============================================================
-- 05. CUSTOMER REVIEW SCORES BY CATEGORY
-- Business Question:
-- Which product categories have high or low review scores?
--
-- Purpose:
-- Compare category sales with customer satisfaction.
--
-- Method:
-- Aggregate reviews to one score per order first.
-- ============================================================

WITH order_review_scores AS (

    SELECT
        order_id,

        AVG(review_score) AS average_order_review_score

    FROM order_reviews

    WHERE review_score IS NOT NULL

    GROUP BY order_id

)

SELECT
    COALESCE(
        pct.product_category_name_english,
        p.product_category_name,
        'Unknown'
    ) AS product_category,

    COUNT(*) AS reviewed_order_items,

    COUNT(DISTINCT oi.order_id) AS reviewed_orders,

    ROUND(
        AVG(ors.average_order_review_score)::NUMERIC,
        2
    ) AS average_review_score,

    ROUND(
        SUM(oi.price)::NUMERIC,
        2
    ) AS product_sales_for_reviewed_orders

FROM order_items oi

INNER JOIN products p
    ON oi.product_id = p.product_id

INNER JOIN order_review_scores ors
    ON oi.order_id = ors.order_id

LEFT JOIN product_category_name_translation pct
    ON p.product_category_name =
       pct.product_category_name

GROUP BY
    COALESCE(
        pct.product_category_name_english,
        p.product_category_name,
        'Unknown'
    )

ORDER BY average_review_score DESC;

-- ============================================================
-- 06. DELIVERY DELAYS BY PRODUCT CATEGORY
-- Business Question:
-- Which product categories have the longest delivery delays?
--
-- Purpose:
-- Identify categories associated with late deliveries.
--
-- Definition:
-- Delivery delay = Actual delivery date - Estimated date
-- Positive values indicate late delivery.
-- ============================================================

WITH order_delivery AS (

    SELECT
        order_id,

        MAX(order_delivered_customer_date)
            AS actual_delivery_date,

        MAX(order_estimated_delivery_date)
            AS estimated_delivery_date

    FROM orders

    WHERE order_status = 'delivered'

      AND order_delivered_customer_date IS NOT NULL

      AND order_estimated_delivery_date IS NOT NULL

    GROUP BY order_id

)

SELECT
    COALESCE(
        pct.product_category_name_english,
        p.product_category_name,
        'Unknown'
    ) AS product_category,

    COUNT(DISTINCT oi.order_id) AS delivered_orders,

    ROUND(
        AVG(
            EXTRACT(
                EPOCH FROM (
                    od.actual_delivery_date
                    - od.estimated_delivery_date
                )
            ) / 86400.0
        )::NUMERIC,
        2
    ) AS average_delivery_delay_days,

    COUNT(DISTINCT oi.order_id) FILTER (
        WHERE od.actual_delivery_date
              > od.estimated_delivery_date
    ) AS late_orders,

    ROUND(
        (
            COUNT(DISTINCT oi.order_id) FILTER (
                WHERE od.actual_delivery_date
                      > od.estimated_delivery_date
            )::NUMERIC
            / NULLIF(
                COUNT(DISTINCT oi.order_id),
                0
            )
        ) * 100,
        2
    ) AS late_delivery_percentage

FROM order_items oi

INNER JOIN products p
    ON oi.product_id = p.product_id

INNER JOIN order_delivery od
    ON oi.order_id = od.order_id

LEFT JOIN product_category_name_translation pct
    ON p.product_category_name =
       pct.product_category_name

GROUP BY
    COALESCE(
        pct.product_category_name_english,
        p.product_category_name,
        'Unknown'
    )

ORDER BY late_delivery_percentage DESC;

