select
    c.customer_loyalty_level,
    c.customer_gender,
    f.payment_method,
    st.store_location,
    count(distinct c.customer_id)                      as unique_customers,
    count(distinct f.transaction_id)                   as total_transactions,
    round(sum(f.total_amount), 2)                      as total_spent,
    round(avg(c.customer_income), 2)                   as avg_customer_income,
    round(sum(f.total_amount) / nullif(count(distinct f.transaction_id), 0), 2) as aov
from {{ ref('fct_walmart_sales') }} f
join {{ ref('dim_customer') }} c on f.customer_key = c.customer_key
join {{ ref('dim_store') }} st   on f.store_key = st.store_key
group by
    c.customer_loyalty_level,
    c.customer_gender,
    f.payment_method,
    st.store_location
