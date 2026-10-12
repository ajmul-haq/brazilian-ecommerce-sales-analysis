
-- ============================================================
-- 07. REVIEW ANALYSIS
-- Business Objective: Measure customer satisfaction.
-- Tables: order_reviews, orders, order_items, products,
--         product_category_name_translation
-- ============================================================

-- 01. AVERAGE REVIEW SCORE AND LOW-RATING PERCENTAGE
-- Business Question: What is the average score, and what
-- percentage of reviews have scores of 1 or 2?

SELECT
    COUNT(*) AS total_reviews,
    ROUND(AVG(review_score)::NUMERIC, 2) AS average_review_score,
    ROUND(100.0 * COUNT(*) FILTER (
        WHERE review_score IN (1, 2)
    ) / NULLIF(COUNT(review_score), 0), 2)
        AS low_rating_percentage
FROM order_reviews
WHERE review_score IS NOT NULL;


-- 02. PRODUCT CATEGORIES WITH THE LOWEST RATINGS
-- Business Question: Which categories have the lowest scores?
-- Method: Average each order's reviews before joining items.

WITH review_by_order AS (
    SELECT order_id, AVG(review_score) AS review_score
    FROM order_reviews
    WHERE review_score IS NOT NULL
    GROUP BY order_id
)
SELECT
    COALESCE(pct.product_category_name_english,
             p.product_category_name, 'Unknown') AS category,
    ROUND(AVG(r.review_score)::NUMERIC, 2) AS avg_rating,
    COUNT(DISTINCT oi.order_id) AS reviewed_orders
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
JOIN review_by_order r ON oi.order_id = r.order_id
LEFT JOIN product_category_name_translation pct
    ON p.product_category_name = pct.product_category_name
GROUP BY 1
ORDER BY avg_rating ASC
LIMIT 10;


-- 03. ARE LATE DELIVERIES ASSOCIATED WITH LOWER SCORES?
-- Compare average review scores for late vs. on-time/early orders.

WITH delivery_reviews AS (
    SELECT
        o.order_id,
        AVG(r.review_score) AS review_score,
        MAX(o.order_delivered_customer_date) AS actual_date,
        MAX(o.order_estimated_delivery_date) AS estimated_date
    FROM orders o
    JOIN order_reviews r ON o.order_id = r.order_id
    WHERE o.order_status = 'delivered'
      AND r.review_score IS NOT NULL
      AND o.order_delivered_customer_date IS NOT NULL
      AND o.order_estimated_delivery_date IS NOT NULL
    GROUP BY o.order_id
)
SELECT
    CASE WHEN actual_date > estimated_date
         THEN 'Late delivery'
         ELSE 'On time or early'
    END AS delivery_status,
    COUNT(*) AS reviewed_orders,
    ROUND(AVG(review_score)::NUMERIC, 2) AS avg_review_score
FROM delivery_reviews
GROUP BY 1
ORDER BY avg_review_score;


-- 04. CATEGORIES WITH HIGH SALES AND LOW RATINGS
-- Identify categories with above-average sales but below-average
-- review scores. Benchmarks use all reviewed order items.

WITH review_by_order AS (
    SELECT order_id, AVG(review_score) AS review_score
    FROM order_reviews
    WHERE review_score IS NOT NULL
    GROUP BY order_id
),
category_stats AS (
    SELECT
        COALESCE(pct.product_category_name_english,
                 p.product_category_name, 'Unknown') AS category,
        SUM(oi.price) AS product_sales,
        AVG(r.review_score) AS avg_rating
    FROM order_items oi
    JOIN products p ON oi.product_id = p.product_id
    JOIN review_by_order r ON oi.order_id = r.order_id
    LEFT JOIN product_category_name_translation pct
        ON p.product_category_name = pct.product_category_name
    GROUP BY 1
)
SELECT
    category,
    ROUND(product_sales::NUMERIC, 2) AS product_sales,
    ROUND(avg_rating::NUMERIC, 2) AS avg_rating
FROM category_stats
WHERE product_sales > (SELECT AVG(product_sales) FROM category_stats)
  AND avg_rating < (SELECT AVG(avg_rating) FROM category_stats)
ORDER BY product_sales DESC;
