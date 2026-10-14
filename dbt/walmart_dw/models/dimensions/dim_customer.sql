-- Customer dimension as Slowly Changing Dimension Type 2.
-- The source has no change log, so history is derived from the transactions themselves:
-- a new version starts at the first transaction where any tracked attribute differs from
-- the customer's previous transaction (gaps-and-islands). The true change happened between
-- the last old-version and first new-version transaction; we date it at the first observation.
-- (dbt snapshot is not used: it records changes between pipeline runs, while this history
-- is already contained in one static file.)
with customer_transactions as (
    select
        customer_id,
        transaction_timestamp,
        customer_age,
        customer_gender,
        customer_income,
        customer_loyalty_level,
        md5(concat_ws('|', customer_age, customer_gender, customer_income, customer_loyalty_level)) as attribute_hash
    from {{ ref('stg_walmart_sales') }}
),

flagged as (
    select
        *,
        case
            when attribute_hash = lag(attribute_hash) over (partition by customer_id order by transaction_timestamp)
                then 0
            else 1
        end as is_new_version
    from customer_transactions
),

numbered as (
    select
        *,
        sum(is_new_version) over (
            partition by customer_id
            order by transaction_timestamp
            rows between unbounded preceding and current row
        ) as version_number
    from flagged
),

versions as (
    select
        customer_id,
        version_number,
        min(customer_age)            as customer_age,
        min(customer_gender)         as customer_gender,
        min(customer_income)         as customer_income,
        min(customer_loyalty_level)  as customer_loyalty_level,
        min(transaction_timestamp)   as first_seen_at
    from numbered
    group by customer_id, version_number
)

select
    md5(concat_ws('|', customer_id, version_number))                     as customer_key,
    customer_id,
    customer_age,
    customer_gender,
    customer_income,
    customer_loyalty_level,
    version_number,
    -- first version is open-ended to the past so earlier facts always find a match
    case when version_number = 1 then '1900-01-01'::timestamp else first_seen_at end as valid_from,
    lead(first_seen_at) over (partition by customer_id order by version_number) as valid_to,
    lead(first_seen_at) over (partition by customer_id order by version_number) is null as is_current
from versions
