-- ============================================================
-- 01. AVERAGE DELIVERY TIME
-- Purpose: Calculate average delivery time in days.
-- ============================================================

SELECT
    COUNT(*) AS delivered_orders,

    ROUND(
        AVG(
            EXTRACT(
                EPOCH FROM (
                    order_delivered_customer_date
                    - order_purchase_timestamp
                )
            ) / 86400
        )::NUMERIC,
        2
    ) AS avg_delivery_days

FROM orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL
  AND order_purchase_timestamp IS NOT NULL;
-- ============================================================
-- 02. LATE DELIVERY RATE
-- Purpose: Calculate the percentage of delivered orders
-- that arrived after the estimated delivery date.
-- ============================================================

SELECT
    COUNT(*) AS delivered_orders,

    COUNT(*) FILTER (
        WHERE order_delivered_customer_date
              > order_estimated_delivery_date
    ) AS late_orders,

    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE order_delivered_customer_date
                  > order_estimated_delivery_date
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS late_delivery_percentage

FROM orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL
  AND order_estimated_delivery_date IS NOT NULL;

 -- ============================================================
-- 03. DELIVERY TIME BY STATE
-- Purpose: Identify states with the longest average
-- delivery time.
-- ============================================================

SELECT
    c.customer_state,

    COUNT(DISTINCT o.order_id) AS delivered_orders,

    ROUND(
        AVG(
            EXTRACT(
                EPOCH FROM (
                    o.order_delivered_customer_date
                    - o.order_purchase_timestamp
                )
            ) / 86400
        )::NUMERIC,
        2
    ) AS avg_delivery_days

FROM orders o
JOIN customers c
    ON o.customer_id = c.customer_id

WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
  AND o.order_purchase_timestamp IS NOT NULL

GROUP BY c.customer_state
HAVING COUNT(DISTINCT o.order_id) >= 100

ORDER BY avg_delivery_days DESC;

-- ============================================================
-- 04. UNDELIVERED ORDERS
-- Purpose: Count orders that are not currently marked
-- as delivered, and summarize their statuses.
-- ============================================================

SELECT
    order_status,
    COUNT(*) AS total_orders

FROM orders
WHERE order_status <> 'delivered'

GROUP BY order_status
ORDER BY total_orders DESC;

-- ============================================================
-- 05. DELIVERY DELAY VS CUSTOMER SATISFACTION
-- Purpose: Compare average review scores for late and
-- on-time/early delivered orders.
-- ============================================================

WITH delivery_status AS (
    SELECT
        order_id,

        CASE
            WHEN order_delivered_customer_date
                 > order_estimated_delivery_date
                THEN 'Late'
            ELSE 'On Time or Early'
        END AS delivery_group

    FROM orders

    WHERE order_status = 'delivered'
      AND order_delivered_customer_date IS NOT NULL
      AND order_estimated_delivery_date IS NOT NULL
),

review_by_order AS (
    SELECT
        order_id,
        AVG(review_score) AS avg_review_score
    FROM order_reviews
    GROUP BY order_id
)

SELECT
    d.delivery_group,

    COUNT(*) AS reviewed_orders,

    ROUND(
        AVG(r.avg_review_score)::NUMERIC,
        2
    ) AS avg_review_score

FROM delivery_status d
JOIN review_by_order r
    ON d.order_id = r.order_id

GROUP BY d.delivery_group
ORDER BY avg_review_score DESC;

