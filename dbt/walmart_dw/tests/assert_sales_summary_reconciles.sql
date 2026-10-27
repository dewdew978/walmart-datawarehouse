-- Independent ordinary GROUP BY queries check all 16 levels, not only totals.
{% set time_levels = [(['year', 'quarter', 'month_number'], 0, 'month'), (['year', 'quarter'], 1, 'quarter'), (['year'], 3, 'year'), ([], 7, 'all_time')] %}
{% set dimension_levels = [(['store_location', 'category'], 0, 'location_category'), (['store_location'], 1, 'location'), (['category'], 2, 'category'), ([], 3, 'all_dimensions')] %}
{% set fields = ['year', 'quarter', 'month_number', 'store_location', 'category'] %}
with base as (
    select f.transaction_id, f.quantity_sold, f.total_amount,
           d.year, d.quarter, d.month_number, st.store_location, p.category
    from {{ ref('fct_walmart_sales') }} f
    join {{ ref('dim_date') }} d on f.date_key = d.date_key
    join {{ ref('dim_store') }} st on f.store_key = st.store_key
    join {{ ref('dim_product') }} p on f.product_key = p.product_key
), expected as (
    {% for time_fields, time_mask, time_grain in time_levels %}
    {% for dimension_fields, dimension_mask, dimension_grain in dimension_levels %}
    {% set retained = time_fields + dimension_fields %}
    select
        {{ time_mask * 4 + dimension_mask }} as grouping_id,
        '{{ time_grain }}'::text as time_grain,
        '{{ dimension_grain }}'::text as dimension_grain,
        {% for field in fields %}
        {% if field in retained %}{{ field }}{% else %}null::{{ 'integer' if field in ['year', 'quarter', 'month_number'] else 'text' }}{% endif %} as {{ field }},
        {% endfor %}
        count(distinct transaction_id) as total_transactions,
        coalesce(sum(quantity_sold), 0) as total_units_sold,
        round(coalesce(sum(total_amount), 0), 2) as total_revenue,
        round(sum(total_amount) / nullif(count(distinct transaction_id), 0), 2) as aov
    from base
    {% if retained %}group by {{ retained | join(', ') }}{% endif %}
    {% if not loop.last %}union all{% endif %}
    {% endfor %}
    {% if not loop.last %}union all{% endif %}
    {% endfor %}
), actual as (
    select * from {{ ref('smt_sales_summary') }}
)
select e.grouping_id as expected_grouping_id, a.grouping_id as actual_grouping_id,
       e.total_revenue as expected_revenue, a.total_revenue as actual_revenue
from expected e
full outer join actual a
    on e.grouping_id = a.grouping_id
    {% for field in fields %}
    and e.{{ field }} is not distinct from a.{{ field }}
    {% endfor %}
where e.grouping_id is null or a.grouping_id is null
   or e.time_grain is distinct from a.time_grain
   or e.dimension_grain is distinct from a.dimension_grain
   or e.total_transactions is distinct from a.total_transactions
   or e.total_units_sold is distinct from a.total_units_sold
   or e.total_revenue is distinct from a.total_revenue
   or e.aov is distinct from a.aov
