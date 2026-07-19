-- Tasty Bytes dbt demo: complete 4-step setup with explanations
-- Co-authored with CoCo

-- =============================================================================
-- STEP 1: Create CSV file format and S3 external stage
-- =============================================================================
-- The raw data lives in a public S3 bucket maintained by Snowflake for quickstarts.
-- We need a file format to tell Snowflake how to parse the CSV files, and an
-- external stage that points to the S3 bucket location.

CREATE OR REPLACE FILE FORMAT tasty_bytes_dbt_db.public.csv_ff
  TYPE = 'CSV';

CREATE OR REPLACE STAGE tasty_bytes_dbt_db.public.s3load
  COMMENT = 'Quickstarts S3 Stage Connection'
  URL = 's3://sfquickstarts/frostbyte_tastybytes/'
  FILE_FORMAT = tasty_bytes_dbt_db.public.csv_ff;

-- Verify the stage is accessible:
-- LS @tasty_bytes_dbt_db.public.s3load/raw_pos/;


-- =============================================================================
-- STEP 2: Load data into all 8 raw tables from S3
-- =============================================================================
-- The raw schema already has empty tables (country, franchise, location, menu,
-- truck, order_header, order_detail, customer_loyalty). COPY INTO loads the
-- compressed CSV files from S3 into each table. Each subfolder in S3 corresponds
-- to one table.

-- Small dimension tables
COPY INTO tasty_bytes_dbt_db.raw.country
  FROM @tasty_bytes_dbt_db.public.s3load/raw_pos/country/;

COPY INTO tasty_bytes_dbt_db.raw.franchise
  FROM @tasty_bytes_dbt_db.public.s3load/raw_pos/franchise/;

COPY INTO tasty_bytes_dbt_db.raw.location
  FROM @tasty_bytes_dbt_db.public.s3load/raw_pos/location/;

COPY INTO tasty_bytes_dbt_db.raw.menu
  FROM @tasty_bytes_dbt_db.public.s3load/raw_pos/menu/;

COPY INTO tasty_bytes_dbt_db.raw.truck
  FROM @tasty_bytes_dbt_db.public.s3load/raw_pos/truck/;

-- Large fact tables (millions of rows - may take a minute)
COPY INTO tasty_bytes_dbt_db.raw.order_header
  FROM @tasty_bytes_dbt_db.public.s3load/raw_pos/order_header/;

COPY INTO tasty_bytes_dbt_db.raw.order_detail
  FROM @tasty_bytes_dbt_db.public.s3load/raw_pos/order_detail/;

-- Customer data (separate path in S3)
COPY INTO tasty_bytes_dbt_db.raw.customer_loyalty
  FROM @tasty_bytes_dbt_db.public.s3load/raw_customer/customer_loyalty/;


-- =============================================================================
-- STEP 3: Install dbt packages (run in terminal, not SQL)
-- =============================================================================
-- This installs any dependencies declared in packages.yml.
-- In this project, no external packages are required, but running deps
-- ensures the project is properly initialized.
--
-- Command:  dbt deps --project-dir tasty_bytes_dbt_demo


-- =============================================================================
-- STEP 4: Run dbt build to compile and execute all models + tests
-- =============================================================================
-- `dbt build` runs models AND tests in dependency order:
--   1. Source tests (50 tests on raw tables: not_null, unique, relationships, etc.)
--   2. Staging views (8 views in DEV schema that select from raw tables)
--   3. Mart tables (3 tables: orders, customer_loyalty_metrics, sales_metrics_by_location)
--
-- The profiles.yml maps target "dev" to:
--   database: TASTY_BYTES_DBT_DB
--   schema:   DEV
--   warehouse: TASTY_BYTES_DBT_WH
--
-- Command:  dbt build --project-dir tasty_bytes_dbt_demo
--
-- Expected result: PASS=61 WARN=0 ERROR=0 SKIP=0 TOTAL=61
--
-- Models created:
--   Staging (views):
--     - dev.raw_pos_country
--     - dev.raw_pos_franchise
--     - dev.raw_pos_location
--     - dev.raw_pos_menu
--     - dev.raw_pos_truck
--     - dev.raw_pos_order_header
--     - dev.raw_pos_order_detail
--     - dev.raw_customer_customer_loyalty
--
--   Marts (tables):
--     - dev.orders              (joins order_header + order_detail + truck + location)
--     - dev.customer_loyalty_metrics  (aggregated customer spend & order metrics)
--     - dev.sales_metrics_by_location (Python model: revenue metrics per location)
