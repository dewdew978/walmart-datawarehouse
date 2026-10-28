-- Walmart Dashboard recreation from "Metabase - Walmart.pdf".
-- Save each numbered SELECT as a separate Metabase question.
-- Revenue/AOV are currency; transactions and units are plain numbers.

-- 01 Total Revenue | Number | USD, 2 decimals
select total_revenue
from smt_sales_summary where grouping_id = 31;

-- 02 Total Transactions | Number | plain integer (no currency symbol)
select total_transactions
from smt_sales_summary where grouping_id = 31;

-- 03 Total Units Sold | Number | plain integer (no currency symbol)
select total_units_sold
from smt_sales_summary where grouping_id = 31;

-- 04 Average Order Value | Number | USD, 2 decimals
select aov
from smt_sales_summary where grouping_id = 31;

-- 05 M01 Sales by City | Horizontal bar | city -> revenue
select store_location, total_revenue
from smt_sales_summary
where time_grain = 'all_time' and dimension_grain = 'location'
order by total_revenue desc;

-- 06 M01 Promotion Comparison | Bar | promotion_type -> units_per_transaction
-- Descriptive comparison; does not establish a causal promotion effect.
select promotion_type,
       round(sum(quantity_sold)::numeric / nullif(count(distinct transaction_id), 0), 2)
           as units_per_transaction
from fct_walmart_sales
group by promotion_type
order by units_per_transaction;

-- 07 M01 Monthly Sales Trend | Line | month -> revenue | Year: 2024
select make_date(year, month_number, 1) as month, total_revenue
from smt_sales_summary
where time_grain = 'month' and dimension_grain = 'all_dimensions' and year = 2024
order by month;

-- 08 M02 Income and Spending | Combo, two axes | membership tier
-- Income is averaged over sale records, not over distinct customers or metric rows.
select c.customer_loyalty_level,
       sum(f.total_amount) as total_spent,
       round(avg(c.customer_income), 2) as sales_weighted_avg_customer_income
from fct_walmart_sales f
join dim_customer c on f.customer_key = c.customer_key
group by c.customer_loyalty_level
order by case c.customer_loyalty_level
    when 'Bronze' then 1 when 'Silver' then 2 when 'Gold' then 3 when 'Platinum' then 4
end;

-- 09 M02 Revenue by Payment Method | Donut | value = revenue, not customer counts
select payment_method, sum(total_spent) as total_revenue
from m02_customer_intelligence
group by payment_method
order by total_revenue desc;

-- 10 M03 Stockout Rate by Lead Time | Line | days -> rate
-- Rate is already 0..100; format with a % suffix, do not multiply by 100 again.
select sp.supplier_lead_time as supplier_lead_time_days,
       count(*) as sales_events,
       count(*) filter (where f.stockout_indicator) as stockout_events,
       round(100.0 * count(*) filter (where f.stockout_indicator) / nullif(count(*), 0), 2)
           as stockout_rate_pct
from fct_walmart_sales f
join dim_supplier sp on f.supplier_key = sp.supplier_key
group by sp.supplier_lead_time
order by sp.supplier_lead_time;

-- 11 M03 Holiday vs Normal Day Stockout Rate | Bar, not donut
-- Each group uses its own sales-event denominator, so unequal exposure is respected.
select case when d.holiday_indicator then 'Holiday' else 'Normal day' end as day_type,
       count(*) as sales_events,
       count(*) filter (where f.stockout_indicator) as stockout_events,
       round(100.0 * count(*) filter (where f.stockout_indicator) / nullif(count(*), 0), 2)
           as stockout_rate_pct
from fct_walmart_sales f
join dim_date d on f.date_key = d.date_key
group by d.holiday_indicator
order by d.holiday_indicator;

-- 12 M03 Forecast Variance by Weather | Bar | category axis is not continuous
-- Signed error, in demand units: positive = actual above forecast; negative = actual below.
select weather_conditions,
       round(avg(actual_demand - forecasted_demand), 2) as avg_forecast_variance
from fct_walmart_sales
group by weather_conditions
order by weather_conditions;

-- 13 M04 Post-upgrade Spending vs Control | Grouped bar | USD per 30 days
select from_tier || ' -> ' || to_tier as tier_transition,
       spend_per_30d_after_upgrade, control_spend_per_30d
from m04_loyalty_upgrade_impact
order by case from_tier when 'Bronze' then 1 when 'Silver' then 2 when 'Gold' then 3 end;

-- 14 M04 Uplift vs Control | Bar | fraction -> Metabase percentage format
-- 0.663 should display as 66.3%; no additional SQL multiplication by 100.
select from_tier || ' -> ' || to_tier as tier_transition, uplift_vs_control
from m04_loyalty_upgrade_impact
order by case from_tier when 'Bronze' then 1 when 'Silver' then 2 when 'Gold' then 3 end;

-- 15 Quarterly Revenue Trend | Line | quarter -> revenue | Year: 2024
select make_date(year, (quarter - 1) * 3 + 1, 1) as quarter_start, total_revenue
from smt_sales_summary
where time_grain = 'quarter' and dimension_grain = 'all_dimensions' and year = 2024
order by quarter_start;
