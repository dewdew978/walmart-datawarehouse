-- customer attributes vary per customer_id in the source, so each distinct
-- attribute combination is its own member (the profile as of that transaction).
with distinct_customers as (
    select distinct
        customer_id,
        customer_age,
        customer_gender,
        customer_income,
        customer_loyalty_level
    from {{ ref('stg_walmart_sales') }}
)

select
    md5(concat_ws('|', customer_id, customer_age, customer_gender, customer_income, customer_loyalty_level)) as customer_key,
    customer_id,
    customer_age,
    customer_gender,
    customer_income,
    customer_loyalty_level
from distinct_customers
