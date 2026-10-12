/* ============================================================
   OLIST BRAZILIAN E-COMMERCE PROJECT
   02_data_validation.sql

   Purpose:
   Validate row counts, duplicates, NULL values,
   invalid values, and date consistency.
   ============================================================ */


/* ============================================================
   1. ROW COUNT VALIDATION
   ============================================================ */

SELECT COUNT(*) AS total_customers
FROM customers;

SELECT COUNT(*) AS total_orders
FROM orders;

SELECT COUNT(*) AS total_order_items
FROM order_items;

SELECT COUNT(*) AS total_products
FROM products;

SELECT COUNT(*) AS total_sellers
FROM sellers;

SELECT COUNT(*) AS total_payments
FROM order_payments;

SELECT COUNT(*) AS total_reviews
FROM order_reviews;

SELECT COUNT(*) AS total_geolocation_records
FROM geolocation;

SELECT COUNT(*) AS total_category_records
FROM product_category_name_translation;


/* ============================================================
   2. DUPLICATE VALIDATION
   ============================================================ */

-- Duplicate customer IDs
SELECT
    customer_id,
    COUNT(*) AS duplicate_count
FROM customers
GROUP BY customer_id
HAVING COUNT(*) > 1;


-- Duplicate order IDs
SELECT
    order_id,
    COUNT(*) AS duplicate_count
FROM orders
GROUP BY order_id
HAVING COUNT(*) > 1;


-- Duplicate product IDs
SELECT
    product_id,
    COUNT(*) AS duplicate_count
FROM products
GROUP BY product_id
HAVING COUNT(*) > 1;


-- Duplicate seller IDs
SELECT
    seller_id,
    COUNT(*) AS duplicate_count
FROM sellers
GROUP BY seller_id
HAVING COUNT(*) > 1;


/* ============================================================
   3. NULL VALUE VALIDATION — CUSTOMERS
   ============================================================ */

SELECT
    COUNT(*) FILTER (WHERE customer_id IS NULL) AS customer_id_nulls,
    COUNT(*) FILTER (WHERE customer_unique_id IS NULL) AS customer_unique_id_nulls,
    COUNT(*) FILTER (WHERE customer_zip_code_prefix IS NULL) AS zip_code_nulls,
    COUNT(*) FILTER (WHERE customer_city IS NULL) AS city_nulls,
    COUNT(*) FILTER (WHERE customer_state IS NULL) AS state_nulls
FROM customers;


/* ============================================================
   4. NULL VALUE VALIDATION — ORDERS
   ============================================================ */

SELECT
    COUNT(*) FILTER (WHERE order_id IS NULL) AS order_id_nulls,
    COUNT(*) FILTER (WHERE customer_id IS NULL) AS customer_id_nulls,
    COUNT(*) FILTER (WHERE order_status IS NULL) AS order_status_nulls,
    COUNT(*) FILTER (WHERE order_purchase_timestamp IS NULL) AS purchase_date_nulls,
    COUNT(*) FILTER (WHERE order_approved_at IS NULL) AS approved_date_nulls,
    COUNT(*) FILTER (WHERE order_delivered_carrier_date IS NULL) AS carrier_date_nulls,
    COUNT(*) FILTER (WHERE order_delivered_customer_date IS NULL) AS customer_delivery_date_nulls,
    COUNT(*) FILTER (WHERE order_estimated_delivery_date IS NULL) AS estimated_delivery_date_nulls
FROM orders;


/* ============================================================
   5. NULL VALUE VALIDATION — ORDER ITEMS
   ============================================================ */

SELECT
    COUNT(*) FILTER (WHERE order_id IS NULL) AS order_id_nulls,
    COUNT(*) FILTER (WHERE order_item_id IS NULL) AS order_item_id_nulls,
    COUNT(*) FILTER (WHERE product_id IS NULL) AS product_id_nulls,
    COUNT(*) FILTER (WHERE seller_id IS NULL) AS seller_id_nulls,
    COUNT(*) FILTER (WHERE shipping_limit_date IS NULL) AS shipping_date_nulls,
    COUNT(*) FILTER (WHERE price IS NULL) AS price_nulls,
    COUNT(*) FILTER (WHERE freight_value IS NULL) AS freight_value_nulls
FROM order_items;


/* ============================================================
   6. NULL VALUE VALIDATION — PRODUCTS
   ============================================================ */

SELECT
    COUNT(*) FILTER (WHERE product_id IS NULL) AS product_id_nulls,
    COUNT(*) FILTER (WHERE product_category_name IS NULL) AS category_nulls,
    COUNT(*) FILTER (WHERE product_name_lenght IS NULL) AS name_length_nulls,
    COUNT(*) FILTER (WHERE product_description_lenght IS NULL) AS description_length_nulls,
    COUNT(*) FILTER (WHERE product_photos_qty IS NULL) AS photo_quantity_nulls,
    COUNT(*) FILTER (WHERE product_weight_g IS NULL) AS weight_nulls,
    COUNT(*) FILTER (WHERE product_length_cm IS NULL) AS length_nulls,
    COUNT(*) FILTER (WHERE product_height_cm IS NULL) AS height_nulls,
    COUNT(*) FILTER (WHERE product_width_cm IS NULL) AS width_nulls
FROM products;


/* ============================================================
   7. NULL VALUE VALIDATION — SELLERS
   ============================================================ */

SELECT
    COUNT(*) FILTER (WHERE seller_id IS NULL) AS seller_id_nulls,
    COUNT(*) FILTER (WHERE seller_zip_code_prefix IS NULL) AS zip_code_nulls,
    COUNT(*) FILTER (WHERE seller_city IS NULL) AS city_nulls,
    COUNT(*) FILTER (WHERE seller_state IS NULL) AS state_nulls
FROM sellers;


/* ============================================================
   8. NULL VALUE VALIDATION — PAYMENTS
   ============================================================ */

SELECT
    COUNT(*) FILTER (WHERE order_id IS NULL) AS order_id_nulls,
    COUNT(*) FILTER (WHERE payment_sequential IS NULL) AS payment_sequence_nulls,
    COUNT(*) FILTER (WHERE payment_type IS NULL) AS payment_type_nulls,
    COUNT(*) FILTER (WHERE payment_installments IS NULL) AS installment_nulls,
    COUNT(*) FILTER (WHERE payment_value IS NULL) AS payment_value_nulls
FROM order_payments;


/* ============================================================
   9. NULL VALUE VALIDATION — REVIEWS
   ============================================================ */

SELECT
    COUNT(*) FILTER (WHERE review_id IS NULL) AS review_id_nulls,
    COUNT(*) FILTER (WHERE order_id IS NULL) AS order_id_nulls,
    COUNT(*) FILTER (WHERE review_score IS NULL) AS review_score_nulls,
    COUNT(*) FILTER (WHERE review_comment_title IS NULL) AS comment_title_nulls,
    COUNT(*) FILTER (WHERE review_comment_message IS NULL) AS comment_message_nulls,
    COUNT(*) FILTER (WHERE review_creation_date IS NULL) AS creation_date_nulls,
    COUNT(*) FILTER (WHERE review_answer_timestamp IS NULL) AS answer_timestamp_nulls
FROM order_reviews;


/* ============================================================
   10. NULL VALUE VALIDATION — GEOLOCATION
   ============================================================ */

SELECT
    COUNT(*) FILTER (WHERE geolocation_zip_code_prefix IS NULL) AS zip_code_nulls,
    COUNT(*) FILTER (WHERE geolocation_lat IS NULL) AS latitude_nulls,
    COUNT(*) FILTER (WHERE geolocation_lng IS NULL) AS longitude_nulls,
    COUNT(*) FILTER (WHERE geolocation_city IS NULL) AS city_nulls,
    COUNT(*) FILTER (WHERE geolocation_state IS NULL) AS state_nulls
FROM geolocation;


/* ============================================================
   11. NULL VALUE VALIDATION — CATEGORY TRANSLATION
   ============================================================ */

SELECT
    COUNT(*) FILTER (WHERE product_category_name IS NULL) AS category_name_nulls,
    COUNT(*) FILTER (WHERE product_category_name_english IS NULL) AS english_category_nulls
FROM product_category_name_translation;


/* ============================================================
   12. ORDER STATUS VALIDATION
   ============================================================ */

SELECT
    order_status,
    COUNT(*) AS order_count
FROM orders
GROUP BY order_status
ORDER BY order_count DESC;


/* ============================================================
   13. PAYMENT TYPE VALIDATION
   ============================================================ */

SELECT
    payment_type,
    COUNT(*) AS payment_count
FROM order_payments
GROUP BY payment_type
ORDER BY payment_count DESC;


/* ============================================================
   14. NEGATIVE PRICE VALIDATION
   ============================================================ */

SELECT *
FROM order_items
WHERE price < 0;


/* ============================================================
   15. NEGATIVE FREIGHT VALUE VALIDATION
   ============================================================ */

SELECT *
FROM order_items
WHERE freight_value < 0;


/* ============================================================
   16. NEGATIVE PAYMENT VALUE VALIDATION
   ============================================================ */

SELECT *
FROM order_payments
WHERE payment_value < 0;


/* ============================================================
   17. INVALID PAYMENT INSTALLMENTS
   ============================================================ */

SELECT *
FROM order_payments
WHERE payment_installments < 1;


/* ============================================================
   18. INVALID PRODUCT DIMENSIONS
   ============================================================ */

SELECT *
FROM products
WHERE product_weight_g < 0
   OR product_length_cm < 0
   OR product_height_cm < 0
   OR product_width_cm < 0;


/* ============================================================
   19. ORDER DATE CONSISTENCY
   ============================================================ */

-- Approved date should not be before purchase date
SELECT *
FROM orders
WHERE order_approved_at < order_purchase_timestamp;


/* ============================================================
   20. DELIVERY DATE CONSISTENCY
   ============================================================ */

-- Customer delivery should not be before carrier delivery
SELECT *
FROM orders
WHERE order_delivered_customer_date IS NOT NULL
  AND order_delivered_carrier_date IS NOT NULL
  AND order_delivered_customer_date < order_delivered_carrier_date;


/* ============================================================
   21. DELIVERY DATE VS PURCHASE DATE
   ============================================================ */

-- Customer delivery should not be before purchase
SELECT *
FROM orders
WHERE order_delivered_customer_date IS NOT NULL
  AND order_delivered_customer_date < order_purchase_timestamp;


/* ============================================================
   22. ESTIMATED DELIVERY DATE VALIDATION
   ============================================================ */

-- Estimated delivery should normally be after purchase
SELECT *
FROM orders
WHERE order_estimated_delivery_date < order_purchase_timestamp;


/* ============================================================
   23. ORDER STATUS SUMMARY
   ============================================================ */

SELECT
    order_status,
    COUNT(*) AS order_count,
    ROUND(
        COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER (),
        2
    ) AS percentage
FROM orders
GROUP BY order_status
ORDER BY order_count DESC;


/* ============================================================
   24. ORDER DATE RANGE
   ============================================================ */

SELECT
    MIN(order_purchase_timestamp) AS earliest_order,
    MAX(order_purchase_timestamp) AS latest_order
FROM orders;


/* ============================================================
   25. CUSTOMER STATE DISTRIBUTION
   ============================================================ */

SELECT
    customer_state,
    COUNT(*) AS customer_count
FROM customers
GROUP BY customer_state
ORDER BY customer_count DESC;


/* ============================================================
   26. PRODUCT CATEGORY DISTRIBUTION
   ============================================================ */

SELECT
    product_category_name,
    COUNT(*) AS product_count
FROM products
GROUP BY product_category_name
ORDER BY product_count DESC;

--for english version

SELECT
    pct.product_category_name_english AS product_category,
    COUNT(*) AS product_count
FROM products p
LEFT JOIN product_category_name_translation pct
    ON p.product_category_name = pct.product_category_name
GROUP BY pct.product_category_name_english
ORDER BY product_count DESC;

/* ============================================================
   27. REVIEW SCORE VALIDATION
   ============================================================ */

SELECT
    review_score,
    COUNT(*) AS review_count
FROM order_reviews
GROUP BY review_score
ORDER BY review_score;

/* ============================================================
   28. INVALID REVIEW SCORES
   ============================================================ */

SELECT *
FROM order_reviews
WHERE review_score < 1
   OR review_score > 5;


/* ============================================================
   29. FINAL TABLE ROW COUNT SUMMARY
   ============================================================ */

SELECT
    'customers' AS table_name,
    COUNT(*) AS row_count
FROM customers

UNION ALL

SELECT
    'orders',
    COUNT(*)
FROM orders

UNION ALL

SELECT
    'order_items',
    COUNT(*)
FROM order_items

UNION ALL

SELECT
    'products',
    COUNT(*)
FROM products

UNION ALL

SELECT
    'sellers',
    COUNT(*)
FROM sellers

UNION ALL

SELECT
    'order_payments',
    COUNT(*)
FROM order_payments

UNION ALL

SELECT
    'order_reviews',
    COUNT(*)
FROM order_reviews

UNION ALL

SELECT
    'geolocation',
    COUNT(*)
FROM geolocation

UNION ALL

SELECT
    'product_category_translation',
    COUNT(*)
FROM product_category_name_translation

ORDER BY row_count DESC;

