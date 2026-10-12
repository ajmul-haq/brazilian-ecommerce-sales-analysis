-- ============================================================
-- 01. MOST POPULAR PAYMENT METHODS
-- Business Question:
-- Which payment methods are used most frequently?
--
-- Purpose:
-- Identify customer payment preferences.
--
-- Metrics:
-- Total payment records, unique orders, and payment share.
-- ============================================================

SELECT
    payment_type,

    COUNT(*) AS total_payment_records,

    COUNT(DISTINCT order_id) AS total_orders,

    ROUND(
        (
            COUNT(*)::NUMERIC
            / NULLIF(SUM(COUNT(*)) OVER (), 0)
        ) * 100,
        2
    ) AS payment_record_percentage

FROM order_payments

GROUP BY payment_type

ORDER BY total_payment_records DESC;

-- ============================================================
-- 02. TOTAL PAYMENT VALUE BY PAYMENT METHOD
-- Business Question:
-- What is the total recorded payment value for each method?
--
-- Purpose:
-- Compare transaction values across payment methods.
--
-- Metric:
-- SUM(payment_value)
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
    ) AS average_payment_record_value,

    ROUND(
        (
            SUM(payment_value)
            / NULLIF(SUM(SUM(payment_value)) OVER (), 0)
        ) * 100,
        2
    ) AS payment_value_percentage

FROM order_payments

GROUP BY payment_type

ORDER BY total_payment_value DESC;
-- ============================================================
-- 03. INSTALLMENT PAYMENT ANALYSIS
-- Business Question:
-- How frequently are installment payments used?
--
-- Purpose:
-- Understand customer use of installment-based payments.
--
-- Definition:
-- More than 1 installment = installment payment.
-- ============================================================

SELECT
    COUNT(*) AS total_payment_records,

    COUNT(*) FILTER (
        WHERE payment_installments = 1
    ) AS single_installment_records,

    COUNT(*) FILTER (
        WHERE payment_installments > 1
    ) AS multiple_installment_records,

    ROUND(
        (
            COUNT(*) FILTER (
                WHERE payment_installments > 1
            )::NUMERIC
            / NULLIF(COUNT(*), 0)
        ) * 100,
        2
    ) AS installment_record_percentage,

    ROUND(
        AVG(payment_installments)::NUMERIC,
        2
    ) AS average_installments

FROM order_payments;

-- ============================================================
-- 04. INSTALLMENT USE BY PAYMENT METHOD
-- Business Question:
-- Which payment methods are most associated with installments?
--
-- Purpose:
-- Compare installment usage across payment methods.
-- ============================================================

SELECT
    payment_type,

    COUNT(*) AS total_payment_records,

    COUNT(*) FILTER (
        WHERE payment_installments > 1
    ) AS installment_payment_records,

    ROUND(
        (
            COUNT(*) FILTER (
                WHERE payment_installments > 1
            )::NUMERIC
            / NULLIF(COUNT(*), 0)
        ) * 100,
        2
    ) AS installment_percentage,

    ROUND(
        AVG(payment_installments)::NUMERIC,
        2
    ) AS average_installments

FROM order_payments

GROUP BY payment_type

ORDER BY installment_percentage DESC;

-- ============================================================
-- 05. AVERAGE ORDER PAYMENT VALUE BY PAYMENT METHOD
-- Business Question:
-- How does average order payment value differ by method?
--
-- Purpose:
-- Compare the average payment amount of orders using each method.
--
-- Method:
-- Aggregate each payment method to one amount per order first.
-- An order can use more than one payment method.
-- ============================================================

WITH order_method_payments AS (

    SELECT
        order_id,
        payment_type,

        SUM(payment_value) AS method_payment_value

    FROM order_payments

    GROUP BY
        order_id,
        payment_type

)

SELECT
    payment_type,

    COUNT(*) AS orders_using_payment_method,

    ROUND(
        SUM(method_payment_value)::NUMERIC,
        2
    ) AS total_payment_value,

    ROUND(
        AVG(method_payment_value)::NUMERIC,
        2
    ) AS average_order_payment_by_method

FROM order_method_payments

GROUP BY payment_type

ORDER BY average_order_payment_by_method DESC;

-- ============================================================
-- 06. UNUSUAL PAYMENT RECORDS
-- Business Question:
-- Are there payment records with suspicious or invalid values?
--
-- Purpose:
-- Identify records that need data-quality investigation.
--
-- Checks:
-- Missing values, non-positive amounts, invalid installment
-- counts, and unusually large payment values.
-- ============================================================

WITH payment_threshold AS (

    SELECT
        PERCENTILE_CONT(0.99)
        WITHIN GROUP (
            ORDER BY payment_value
        ) AS payment_value_99th_percentile

    FROM order_payments

    WHERE payment_value IS NOT NULL
      AND payment_value >= 0

)

SELECT
    op.order_id,
    op.payment_sequential,
    op.payment_type,
    op.payment_installments,
    op.payment_value,

    CASE
        WHEN op.order_id IS NULL
            THEN 'Missing order ID'

        WHEN op.payment_type IS NULL
            THEN 'Missing payment type'

        WHEN op.payment_value IS NULL
            THEN 'Missing payment value'

        WHEN op.payment_value < 0
            THEN 'Negative payment value'

        WHEN op.payment_value = 0
            THEN 'Zero payment value'

        WHEN op.payment_installments IS NULL
            THEN 'Missing installment count'

        WHEN op.payment_installments < 1
            THEN 'Invalid installment count'

        WHEN op.payment_value >
             pt.payment_value_99th_percentile
            THEN 'Payment value above 99th percentile'

    END AS issue_type

FROM order_payments op

CROSS JOIN payment_threshold pt

WHERE
       op.order_id IS NULL
    OR op.payment_type IS NULL
    OR op.payment_value IS NULL
    OR op.payment_value <= 0
    OR op.payment_installments IS NULL
    OR op.payment_installments < 1
    OR op.payment_value >
       pt.payment_value_99th_percentile

ORDER BY op.payment_value DESC NULLS LAST;

-- ============================================================
-- 07. PAYMENT VALUE VS ORDER ITEM VALUE
-- Business Question:
-- Do recorded payment totals match product prices plus freight?
--
-- Purpose:
-- Investigate differences between payment and item-level values.
--
-- Note:
-- Differences can arise from dataset characteristics or
-- data issues; a difference is not automatically an error.
-- ============================================================

WITH item_totals AS (

    SELECT
        order_id,

        SUM(price + freight_value) AS item_total

    FROM order_items

    GROUP BY order_id

),

payment_totals AS (

    SELECT
        order_id,

        SUM(payment_value) AS payment_total

    FROM order_payments

    GROUP BY order_id

)

SELECT
    i.order_id,

    ROUND(i.item_total::NUMERIC, 2)
        AS product_plus_freight,

    ROUND(p.payment_total::NUMERIC, 2)
        AS total_payment_value,

    ROUND(
        (p.payment_total - i.item_total)::NUMERIC,
        2
    ) AS payment_difference

FROM item_totals i

INNER JOIN payment_totals p
    ON i.order_id = p.order_id

WHERE ABS(
    p.payment_total - i.item_total
) > 0.01

ORDER BY ABS(
    p.payment_total - i.item_total
) DESC

LIMIT 100;