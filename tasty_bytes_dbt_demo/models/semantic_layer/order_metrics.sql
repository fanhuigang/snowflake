{{ config(
    materialized='semantic_view',
    schema='analytics_semantic'
) }}

TABLES(
    {{ ref('fct_orders') }}
)
DIMENSIONS(
    "fct_orders"."order_date" AS order_date,
    "fct_orders"."status" AS status
)
METRICS(
    SUM("fct_orders"."subtotal") AS gross_sales,
    COUNT(DISTINCT "fct_orders"."order_id") AS total_orders
)
