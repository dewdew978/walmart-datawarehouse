-- A grouping level plus its retained dimension values identifies one summary row.
select grouping_id, year, quarter, month_number, store_location, category
from {{ ref('smt_sales_summary') }}
group by grouping_id, year, quarter, month_number, store_location, category
having count(*) > 1
