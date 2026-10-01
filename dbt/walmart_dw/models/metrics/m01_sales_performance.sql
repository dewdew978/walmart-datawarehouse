select
    d.year,
    d.month_name,
    p.category,
    st.store_location,
    d.holiday_indicator,
    f.promotion_type,
    count(distinct f.transaction_id)                   as total_transactions,
    sum(f.quantity_sold)                               as total_units_sold,
    round(sum(f.total_amount), 2)                      as total_revenue,
    round(sum(f.total_amount) / nullif(count(distinct f.transaction_id), 0), 2) as aov
from {{ ref('fct_walmart_sales') }} f
join {{ ref('dim_date') }} d on f.date_key = d.date_key
join {{ ref('dim_product') }} p on f.product_key = p.product_key
join {{ ref('dim_store') }} st on f.store_key = st.store_key
group by
    d.year,
    d.month_name,
    p.category,
    st.store_location,
    d.holiday_indicator,
    f.promotion_type
