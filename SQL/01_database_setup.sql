
-- ============================================================
-- PROJECT: BRAZILIAN OLIST E-COMMERCE ANALYSIS
-- FILE: 01_database_setup.sql
-- DATABASE: PostgreSQL 18
-- PURPOSE:
-- 1. Create the project database
-- 2. Create all nine tables
-- 3. Define primary keys and foreign keys
-- 4. Prepare tables for CSV import and analysis
-- ============================================================


-- ============================================================
-- STEP 1: CREATE DATABASE
-- Run this section while connected to an existing database,
-- such as postgres. Do not select olist_ecommerce yet.
-- ============================================================

CREATE DATABASE olist_ecommerce;


-- ============================================================
-- STEP 2: CONNECT TO THE NEW DATABASE
-- In pgAdmin, refresh Databases and connect to olist_ecommerce.
-- Open a NEW Query Tool connected to olist_ecommerce.
-- Run the remaining sections below.
-- ============================================================


-- ============================================================
-- TABLE 1: CUSTOMERS
-- One row per customer record in the source dataset.
-- ============================================================

CREATE TABLE customers (
    customer_id VARCHAR(50) PRIMARY KEY,
    customer_unique_id VARCHAR(50),
    customer_zip_code_prefix VARCHAR(10),
    customer_city VARCHAR(100),
    customer_state VARCHAR(5)
);


-- ============================================================
-- TABLE 2: ORDERS
-- Stores order status and purchase/delivery timestamps.
-- ============================================================

CREATE TABLE orders (
    order_id VARCHAR(50) PRIMARY KEY,
    customer_id VARCHAR(50),
    order_status VARCHAR(30),
    order_purchase_timestamp TIMESTAMP,
    order_approved_at TIMESTAMP,
    order_delivered_carrier_date TIMESTAMP,
    order_delivered_customer_date TIMESTAMP,
    order_estimated_delivery_date TIMESTAMP,

    CONSTRAINT fk_orders_customers
        FOREIGN KEY (customer_id)
        REFERENCES customers(customer_id)
);


-- ============================================================
-- TABLE 3: PRODUCTS
-- Stores product descriptions and physical dimensions.
-- ============================================================

CREATE TABLE products (
    product_id VARCHAR(50) PRIMARY KEY,
    product_category_name VARCHAR(100),
    product_name_lenght INTEGER,
    product_description_lenght INTEGER,
    product_photos_qty INTEGER,
    product_weight_g NUMERIC(10,2),
    product_length_cm NUMERIC(10,2),
    product_height_cm NUMERIC(10,2),
    product_width_cm NUMERIC(10,2)
);


-- ============================================================
-- TABLE 4: SELLERS
-- Stores seller identifiers and locations.
-- ============================================================

CREATE TABLE sellers (
    seller_id VARCHAR(50) PRIMARY KEY,
    seller_zip_code_prefix VARCHAR(10),
    seller_city VARCHAR(100),
    seller_state VARCHAR(5)
);


-- ============================================================
-- TABLE 5: ORDER ITEMS
-- Each row represents an item within an order.
-- An order may contain multiple items and sellers.
-- ============================================================

CREATE TABLE order_items (
    order_id VARCHAR(50),
    order_item_id INTEGER,
    product_id VARCHAR(50),
    seller_id VARCHAR(50),
    shipping_limit_date TIMESTAMP,
    price NUMERIC(12,2),
    freight_value NUMERIC(12,2),

    PRIMARY KEY (order_id, order_item_id),

    CONSTRAINT fk_items_orders
        FOREIGN KEY (order_id)
        REFERENCES orders(order_id),

    CONSTRAINT fk_items_products
        FOREIGN KEY (product_id)
        REFERENCES products(product_id),

    CONSTRAINT fk_items_sellers
        FOREIGN KEY (seller_id)
        REFERENCES sellers(seller_id)
);


-- ============================================================
-- TABLE 6: ORDER PAYMENTS
-- An order can have multiple payment records.
-- ============================================================

CREATE TABLE order_payments (
    order_id VARCHAR(50),
    payment_sequential INTEGER,
    payment_type VARCHAR(30),
    payment_installments INTEGER,
    payment_value NUMERIC(12,2),

    PRIMARY KEY (order_id, payment_sequential),

    CONSTRAINT fk_payments_orders
        FOREIGN KEY (order_id)
        REFERENCES orders(order_id)
);


-- ============================================================
-- TABLE 7: ORDER REVIEWS
-- Stores customer review scores and comments.
-- Review ID is the primary key; an order may have reviews
-- with different review IDs.
-- ============================================================

CREATE TABLE order_reviews (
    review_id VARCHAR(50) PRIMARY KEY,
    order_id VARCHAR(50),
    review_score INTEGER,
    review_comment_title TEXT,
    review_comment_message TEXT,
    review_creation_date TIMESTAMP,
    review_answer_timestamp TIMESTAMP,

    CONSTRAINT fk_reviews_orders
        FOREIGN KEY (order_id)
        REFERENCES orders(order_id)
);


-- ============================================================
-- TABLE 8: GEOLOCATION
-- Stores Brazilian ZIP-code-prefix coordinates.
-- ZIP prefixes can repeat, so no unique ZIP constraint.
-- ============================================================

CREATE TABLE geolocation (
    geolocation_zip_code_prefix VARCHAR(10),
    geolocation_lat NUMERIC(12,8),
    geolocation_lng NUMERIC(12,8),
    geolocation_city VARCHAR(100),
    geolocation_state VARCHAR(5)
);


-- ============================================================
-- TABLE 9: CATEGORY NAME TRANSLATION
-- Maps Portuguese category names to English names.
-- ============================================================

CREATE TABLE product_category_name_translation (
    product_category_name VARCHAR(100) PRIMARY KEY,
    product_category_name_english VARCHAR(100)
);


-- ============================================================
-- STEP 3: CREATE INDEXES
-- These indexes help common joins and analysis queries.
-- ============================================================

CREATE INDEX idx_orders_customer
    ON orders(customer_id);

CREATE INDEX idx_orders_purchase_date
    ON orders(order_purchase_timestamp);

CREATE INDEX idx_orders_status
    ON orders(order_status);

CREATE INDEX idx_items_product
    ON order_items(product_id);

CREATE INDEX idx_items_seller
    ON order_items(seller_id);

CREATE INDEX idx_payments_order
    ON order_payments(order_id);

CREATE INDEX idx_reviews_order
    ON order_reviews(order_id);

CREATE INDEX idx_customers_state
    ON customers(customer_state);

CREATE INDEX idx_geolocation_zip
    ON geolocation(geolocation_zip_code_prefix);


-- ============================================================
-- STEP 4: VERIFY TABLE CREATION
-- Run after the CREATE TABLE and INDEX statements.
-- ============================================================

SELECT
    table_name
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_type = 'BASE TABLE'
ORDER BY table_name;
