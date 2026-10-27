with expected as (
    select
        count(distinct transaction_id) as transactions,
        coalesce(sum(quantity_sold), 0) as units,
        coalesce(sum(total_amount), 0) as revenue
    from {{ ref('fct_walmart_sales') }}
), actual as (
    select * from {{ ref('smt_sales_summary') }} where grouping_id = 31
)
select 'grand_total_mismatch' as failure
from expected e
where (select count(*) from actual) <> 1
   or not exists (
       select 1 from actual a
       where a.total_transactions = e.transactions
         and a.total_units_sold = e.units
         and a.total_revenue = e.revenue
   )
