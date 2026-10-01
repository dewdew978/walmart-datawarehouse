with ranked_products as (
    select
        product_id,
        product_name,
        category,
        row_number() over (
            partition by product_id
            order by transaction_timestamp desc
        ) as rn
    from {{ ref('stg_walmart_sales') }}
)

select
    md5(product_id::text) as product_key,
    product_id,
    product_name,
    category
from ranked_products
where rn = 1
