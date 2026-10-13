-- product_id is not stable in the source (one id appears with several names/categories),
-- so each distinct (product_id, product_name, category) combination is its own member.
with distinct_products as (
    select distinct
        product_id,
        product_name,
        category
    from {{ ref('stg_walmart_sales') }}
)

select
    md5(concat_ws('|', product_id, product_name, category)) as product_key,
    product_id,
    product_name,
    category
from distinct_products
