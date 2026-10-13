-- supplier_lead_time varies per supplier_id in the source,
-- so each distinct (supplier_id, supplier_lead_time) combination is its own member.
with distinct_suppliers as (
    select distinct
        supplier_id,
        supplier_lead_time
    from {{ ref('stg_walmart_sales') }}
)

select
    md5(concat_ws('|', supplier_id, supplier_lead_time)) as supplier_key,
    supplier_id,
    supplier_lead_time
from distinct_suppliers
