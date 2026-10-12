
-- ============================================================
-- 01. REVENUE BY STATE
-- Purpose: Identify states generating the most payment revenue.
-- ============================================================

SELECT
    c.customer_state,
    ROUND(SUM(p.payment_value)::NUMERIC, 2) AS total_revenue,
    COUNT(DISTINCT o.order_id) AS total_orders
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN order_payments p ON o.order_id = p.order_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_state
ORDER BY total_revenue DESC;


-- ============================================================
-- 02. ORDER VOLUME BY STATE
-- Purpose: Find states with the highest delivered order counts.
-- ============================================================

SELECT
    c.customer_state,
    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(DISTINCT c.customer_unique_id) AS unique_customers
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_state
ORDER BY total_orders DESC;


-- ============================================================
-- 03. FREIGHT COST BY STATE
-- Purpose: Identify regions with high total and average freight.
-- ============================================================

SELECT
    c.customer_state,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(oi.freight_value)::NUMERIC, 2) AS total_freight,
    ROUND(AVG(oi.freight_value)::NUMERIC, 2) AS avg_freight_per_item
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_state
ORDER BY avg_freight_per_item DESC;


-- ============================================================
-- 04. LATE DELIVERY RATE BY STATE
-- Purpose: Find states where late deliveries are most common.
-- ============================================================

SELECT
    c.customer_state,
    COUNT(*) AS delivered_orders,
    COUNT(*) FILTER (
        WHERE o.order_delivered_customer_date
              > o.order_estimated_delivery_date
    ) AS late_orders,
    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE o.order_delivered_customer_date
                  > o.order_estimated_delivery_date
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS late_delivery_percentage
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
  AND o.order_estimated_delivery_date IS NOT NULL
GROUP BY c.customer_state
HAVING COUNT(*) >= 100
ORDER BY late_delivery_percentage DESC;


-- ============================================================
-- 05. REGIONAL GROWTH OPPORTUNITIES
-- Purpose: Flag states with many customers but relatively
-- low revenue per customer.
-- Note: This is a screening metric, not proof of growth potential.
-- ============================================================

WITH state_metrics AS (
    SELECT
        c.customer_state,
        COUNT(DISTINCT o.order_id) AS total_orders,
        COUNT(DISTINCT c.customer_unique_id) AS unique_customers,
        SUM(p.payment_value) AS total_revenue
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    JOIN order_payments p ON o.order_id = p.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_state
)
SELECT
    customer_state,
    total_orders,
    unique_customers,
    ROUND(total_revenue::NUMERIC, 2) AS total_revenue,
    ROUND(
        (total_revenue / NULLIF(unique_customers, 0))::NUMERIC,
        2
    ) AS revenue_per_customer
FROM state_metrics
WHERE unique_customers >= 100
ORDER BY revenue_per_customer ASC;
