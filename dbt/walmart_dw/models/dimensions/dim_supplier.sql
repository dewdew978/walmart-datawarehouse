with ranked_suppliers as (
    select
        supplier_id,
        supplier_lead_time,
        row_number() over (
            partition by supplier_id
            order by transaction_timestamp desc
        ) as rn
    from {{ ref('stg_walmart_sales') }}
)

select
    md5(supplier_id::text) as supplier_key,
    supplier_id,
    supplier_lead_time
from ranked_suppliers
where rn = 1
