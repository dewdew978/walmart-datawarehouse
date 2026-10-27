-- Time hierarchy crossed with independent location/category subtotals.
-- Never sum rows across grouping levels: they describe overlapping sales.
with sales as (
    select
        f.transaction_id, f.quantity_sold, f.total_amount,
        d.year, d.quarter, d.month_number,
        st.store_location, p.category
    from {{ ref('fct_walmart_sales') }} f
    join {{ ref('dim_date') }} d on f.date_key = d.date_key
    join {{ ref('dim_store') }} st on f.store_key = st.store_key
    join {{ ref('dim_product') }} p on f.product_key = p.product_key
), aggregated as (
    select
        year, quarter, month_number, store_location, category,
        grouping(year, quarter, month_number, store_location, category) as grouping_id,
        case grouping(year, quarter, month_number)
            when 0 then 'month'
            when 1 then 'quarter'
            when 3 then 'year'
            when 7 then 'all_time'
        end as time_grain,
        case grouping(store_location, category)
            when 0 then 'location_category'
            when 1 then 'location'
            when 2 then 'category'
            when 3 then 'all_dimensions'
        end as dimension_grain,
        count(distinct transaction_id) as total_transactions,
        coalesce(sum(quantity_sold), 0) as total_units_sold,
        round(coalesce(sum(total_amount), 0), 2) as total_revenue,
        round(sum(total_amount) / nullif(count(distinct transaction_id), 0), 2) as aov
    from sales
    group by rollup(year, quarter, month_number), cube(store_location, category)
)
select
    -- JSON preserves nulls and escapes delimiters in real dimension values.
    md5(jsonb_build_array(grouping_id, year, quarter, month_number, store_location, category)::text) as summary_key,
    *
from aggregated
