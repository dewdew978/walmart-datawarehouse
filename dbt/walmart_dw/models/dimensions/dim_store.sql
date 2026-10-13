-- store_id is not stable in the source (one id appears in several locations),
-- so each distinct (store_id, store_location) combination is its own member.
with distinct_stores as (
    select distinct
        store_id,
        store_location
    from {{ ref('stg_walmart_sales') }}
)

select
    md5(concat_ws('|', store_id, store_location)) as store_key,
    store_id,
    store_location
from distinct_stores
