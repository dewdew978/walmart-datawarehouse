with ranked_customers as (
    select
        customer_id,
        customer_age,
        customer_gender,
        customer_income,
        customer_loyalty_level,
        row_number() over (
            partition by customer_id
            order by transaction_timestamp desc
        ) as rn
    from {{ ref('stg_walmart_sales') }}
)

select
    md5(customer_id::text) as customer_key,
    customer_id,
    customer_age,
    customer_gender,
    customer_income,
    customer_loyalty_level
from ranked_customers
where rn = 1
