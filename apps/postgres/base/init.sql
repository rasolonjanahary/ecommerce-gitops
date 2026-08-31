-- ============================================================
-- USERS
-- ============================================================

CREATE USER warehouse WITH PASSWORD '12122005';
CREATE USER airflow WITH PASSWORD '12122005';

-- ============================================================
-- DATABASES
-- ============================================================

CREATE DATABASE warehouse OWNER warehouse;
CREATE DATABASE airflow OWNER airflow;

-- ============================================================
-- DATABASE ECOMMERCE
-- ============================================================

\connect ecommerce

CREATE TABLE IF NOT EXISTS products (
id SERIAL PRIMARY KEY,
name VARCHAR(255) NOT NULL,
price NUMERIC(10, 2) NOT NULL,
stock INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS orders (
id SERIAL PRIMARY KEY,
customer_name VARCHAR(255) NOT NULL,
customer_email VARCHAR(255) NOT NULL,
total_amount NUMERIC(10, 2) NOT NULL,
created_at TIMESTAMP NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS order_items (
id SERIAL PRIMARY KEY,
order_id INTEGER REFERENCES orders(id),
product_id INTEGER REFERENCES products(id),
quantity INTEGER NOT NULL,
unit_price NUMERIC(10, 2) NOT NULL
);

-- ============================================================
-- SAMPLE PRODUCTS
-- ============================================================

INSERT INTO products (name, price, stock)
VALUES
('T-shirt Malagasy', 25000, 50),
('Casquette', 15000, 30),
('Sac en raphia', 40000, 20)
ON CONFLICT DO NOTHING;

-- ============================================================
-- PERMISSIONS ECOMMERCE
-- ============================================================

GRANT CONNECT ON DATABASE ecommerce TO ecommerce;

GRANT USAGE ON SCHEMA public TO ecommerce;
GRANT SELECT, INSERT, UPDATE, DELETE
ON ALL TABLES IN SCHEMA public
TO ecommerce;

GRANT USAGE, SELECT
ON ALL SEQUENCES IN SCHEMA public
TO ecommerce;

-- ============================================================
-- WAREHOUSE
-- ============================================================

\connect warehouse

GRANT CONNECT ON DATABASE warehouse TO warehouse;

GRANT USAGE, CREATE ON SCHEMA public TO warehouse;

-- ============================================================
-- AIRFLOW
-- ============================================================

\connect airflow

GRANT CONNECT ON DATABASE airflow TO airflow;

GRANT USAGE, CREATE ON SCHEMA public TO airflow;
