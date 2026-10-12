
-- ============================================================
-- 01. MONTH-OVER-MONTH REVENUE GROWTH
-- Purpose: Calculate monthly payment revenue and its change
-- compared with the previous month.
-- ============================================================

WITH monthly_revenue AS (
    SELECT
        DATE_TRUNC('month', o.order_purchase_timestamp)::DATE
            AS sales_month,
        SUM(p.payment_value) AS revenue
    FROM orders o
    JOIN order_payments p ON o.order_id = p.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY 1
)
SELECT
    sales_month,
    ROUND(revenue::NUMERIC, 2) AS monthly_revenue,
    ROUND(
        (revenue - LAG(revenue) OVER (ORDER BY sales_month))::NUMERIC,
        2
    ) AS revenue_change,
    ROUND(
        100.0 * (revenue - LAG(revenue) OVER (ORDER BY sales_month))
        / NULLIF(LAG(revenue) OVER (ORDER BY sales_month), 0),
        2
    ) AS mom_growth_percentage
FROM monthly_revenue
ORDER BY sales_month;


-- ============================================================
-- 02. TOP CATEGORIES WITHIN EACH STATE
-- Purpose: Rank product categories by product sales in each
-- customer state. Revenue here means item price, not payments.
-- ============================================================

WITH category_sales AS (
    SELECT
        c.customer_state,
        COALESCE(t.product_category_name_english,
                 p.product_category_name, 'Unknown') AS category,
        SUM(oi.price) AS product_sales
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN products p ON oi.product_id = p.product_id
    LEFT JOIN product_category_name_translation t
        ON p.product_category_name = t.product_category_name
    WHERE o.order_status = 'delivered'
    GROUP BY 1, 2
),
ranked AS (
    SELECT *,
        DENSE_RANK() OVER (
            PARTITION BY customer_state
            ORDER BY product_sales DESC
        ) AS category_rank
    FROM category_sales
)
SELECT
    customer_state,
    category,
    ROUND(product_sales::NUMERIC, 2) AS product_sales,
    category_rank
FROM ranked
WHERE category_rank <= 3
ORDER BY customer_state, category_rank;


-- ============================================================
-- 03. RUNNING TOTAL AND 3-MONTH ROLLING AVERAGE
-- Purpose: Track cumulative revenue and smooth monthly changes.
-- ============================================================

WITH monthly_revenue AS (
    SELECT
        DATE_TRUNC('month', o.order_purchase_timestamp)::DATE
            AS sales_month,
        SUM(p.payment_value) AS revenue
    FROM orders o
    JOIN order_payments p ON o.order_id = p.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY 1
)
SELECT
    sales_month,
    ROUND(revenue::NUMERIC, 2) AS monthly_revenue,
    ROUND(
        SUM(revenue) OVER (ORDER BY sales_month)::NUMERIC, 2
    ) AS running_revenue,
    ROUND(
        AVG(revenue) OVER (
            ORDER BY sales_month
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        )::NUMERIC, 2
    ) AS rolling_3_month_avg
FROM monthly_revenue
ORDER BY sales_month;


-- ============================================================
-- 04. TOP CUSTOMERS BY HISTORICAL SPENDING
-- Purpose: Find customers with the highest total payment value.
-- customer_unique_id groups a customer's multiple records.
-- ============================================================

SELECT
    c.customer_unique_id,
    ROUND(SUM(p.payment_value)::NUMERIC, 2) AS total_spending,
    COUNT(DISTINCT o.order_id) AS total_orders
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_payments p ON o.order_id = p.order_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_unique_id
ORDER BY total_spending DESC
LIMIT 10;


-- ============================================================
-- 05. MONTHLY SALES AND DELIVERY KPIs
-- Purpose: Compare monthly payment revenue, order volume,
-- average delivery days, and late-delivery percentage.
-- ============================================================

SELECT
    DATE_TRUNC('month', o.order_purchase_timestamp)::DATE
        AS sales_month,
    COUNT(DISTINCT o.order_id) AS delivered_orders,
    ROUND(SUM(p.payment_value)::NUMERIC, 2) AS payment_revenue,
    ROUND(
        AVG(EXTRACT(EPOCH FROM (
            o.order_delivered_customer_date
            - o.order_purchase_timestamp
        )) / 86400)::NUMERIC, 2
    ) AS avg_delivery_days,
    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE o.order_delivered_customer_date
                  > o.order_estimated_delivery_date
        ) / NULLIF(COUNT(*) FILTER (
            WHERE o.order_delivered_customer_date IS NOT NULL
              AND o.order_estimated_delivery_date IS NOT NULL
        ), 0),
        2
    ) AS late_delivery_percentage
FROM orders o
JOIN order_payments p ON o.order_id = p.order_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
GROUP BY 1
ORDER BY sales_month;
