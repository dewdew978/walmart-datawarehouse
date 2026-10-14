-- SCD Type 2 integrity for dim_customer: every customer has exactly one current version,
-- and versions are contiguous (each valid_to equals the next version's valid_from).
-- Returns offending customers (test passes when empty).
with checks as (
    select
        customer_id,
        count(*) filter (where is_current)                                    as current_versions,
        count(*) filter (
            where valid_to is distinct from next_valid_from
        )                                                                     as broken_links
    from (
        select
            *,
            lead(valid_from) over (partition by customer_id order by version_number) as next_valid_from
        from {{ ref('dim_customer') }}
    ) v
    group by customer_id
)

select *
from checks
where current_versions <> 1
   or broken_links > 0
