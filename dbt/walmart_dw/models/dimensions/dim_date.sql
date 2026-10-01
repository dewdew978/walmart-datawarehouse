with distinct_dates as (
    select
        transaction_date as full_date,
        trim(to_char(transaction_date, 'Day')) as weekday,
        trim(to_char(transaction_date, 'Month')) as month_name,
        extract(month from transaction_date)::integer as month_number,
        extract(quarter from transaction_date)::integer as quarter,
        extract(year from transaction_date)::integer as year,
        bool_or(holiday_indicator) as holiday_indicator
    from {{ ref('stg_walmart_sales') }}
    group by transaction_date
)

select
    to_char(full_date, 'YYYYMMDD')::integer as date_key,
    full_date,
    weekday,
    month_name,
    month_number,
    quarter,
    year,
    holiday_indicator
from distinct_dates
