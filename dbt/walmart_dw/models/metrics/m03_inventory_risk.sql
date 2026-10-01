select
    st.store_location,
    p.category,
    f.weather_conditions,
    count(*)                                                   as total_events,
    sum(case when f.stockout_indicator = true then 1 else 0 end) as stockout_events,
    round(
        sum(case when f.stockout_indicator = true then 1 else 0 end)::numeric / count(*) * 100, 
        2
    )                                                          as stockout_rate_pct,
    round(avg(f.actual_demand - f.forecasted_demand), 2)       as avg_forecast_variance,
    round(avg(sp.supplier_lead_time), 2)                       as avg_supplier_lead_time_days
from {{ ref('fct_walmart_sales') }} f
join {{ ref('dim_store') }} st     on f.store_key = st.store_key
join {{ ref('dim_product') }} p   on f.product_key = p.product_key
join {{ ref('dim_supplier') }} sp on f.supplier_key = sp.supplier_key
group by
    st.store_location,
    p.category,
    f.weather_conditions
