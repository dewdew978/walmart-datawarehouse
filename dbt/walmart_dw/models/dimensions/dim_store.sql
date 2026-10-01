with ranked_stores as (
    select
        store_id,
        store_location,
        row_number() over (
            partition by store_id
            order by transaction_timestamp desc
        ) as rn
    from {{ ref('stg_walmart_sales') }}
)

select
    md5(store_id::text) as store_key,
    store_id,
    store_location
from ranked_stores
where rn = 1
