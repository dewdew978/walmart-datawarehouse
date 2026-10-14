-- Cleans the raw text load: removes duplicate rows, normalises whitespace/casing,
-- parses mixed date/price/boolean formats and imputes missing customer attributes.
with source_data as (
    select * from {{ source('raw', 'raw_walmart_sales') }}
),

-- Exact duplicate rows share a transaction_id: keep one
deduplicated as (
    select
        *,
        row_number() over (partition by {{ clean_text('transaction_id') }} order by transaction_date) as row_num
    from source_data
),

parsed as (
    select
        {{ clean_text('transaction_id') }}::integer                     as transaction_id,
        {{ clean_text('customer_id') }}::integer                        as customer_id,
        {{ clean_text('product_id') }}::integer                         as product_id,
        {{ clean_text('product_name') }}                                as product_name,
        initcap({{ clean_text('category') }})                           as category,
        {{ clean_text('quantity_sold') }}::integer                      as quantity_sold,
        -- prices may arrive as "$1,234.56"
        replace(replace({{ clean_text('unit_price') }}, '$', ''), ',', '')::numeric(10, 2) as unit_price,
        -- timestamps arrive as "M/D/YYYY H:MI" or ISO "YYYY-MM-DD HH:MI:SS"
        case
            when {{ clean_text('transaction_date') }} ~ '^\d{4}-'
                then to_timestamp({{ clean_text('transaction_date') }}, 'YYYY-MM-DD HH24:MI:SS')::timestamp
            else to_timestamp({{ clean_text('transaction_date') }}, 'MM/DD/YYYY HH24:MI')::timestamp
        end                                                             as transaction_timestamp,
        {{ clean_text('store_id') }}::integer                           as store_id,
        -- "chicago ,  IL" -> "Chicago, IL"
        regexp_replace({{ clean_text('store_location') }}, '\s*,\s*', ',')  as store_location_raw,
        {{ clean_text('inventory_level') }}::integer                    as inventory_level,
        {{ clean_text('reorder_point') }}::integer                      as reorder_point,
        {{ clean_text('reorder_quantity') }}::integer                   as reorder_quantity,
        {{ clean_text('supplier_id') }}::integer                        as supplier_id,
        {{ clean_text('supplier_lead_time') }}::integer                 as supplier_lead_time,
        {{ clean_text('customer_age') }}::integer                       as customer_age,
        initcap({{ clean_text('customer_gender') }})                    as customer_gender,
        {{ clean_text('customer_income') }}::numeric(12, 2)             as customer_income,
        initcap({{ clean_text('customer_loyalty_level') }})             as customer_loyalty_level,
        initcap({{ clean_text('payment_method') }})                     as payment_method,
        {{ clean_bool('promotion_applied') }}                           as promotion_applied,
        coalesce(nullif({{ clean_text('promotion_type') }}, 'None'), 'No Promotion') as promotion_type,
        initcap({{ clean_text('weather_conditions') }})                 as weather_conditions,
        {{ clean_bool('holiday_indicator') }}                           as holiday_indicator,
        {{ clean_bool('stockout_indicator') }}                          as stockout_indicator,
        {{ clean_text('forecasted_demand') }}::integer                  as forecasted_demand,
        {{ clean_text('actual_demand') }}::integer                      as actual_demand
    from deduplicated
    where row_num = 1
)

select
    transaction_id,
    customer_id,
    product_id,
    product_name,
    category,
    quantity_sold,
    unit_price,
    transaction_timestamp,
    transaction_timestamp::date                                         as transaction_date,
    store_id,
    initcap(split_part(store_location_raw, ',', 1)) || ', '
        || upper(split_part(store_location_raw, ',', 2))                as store_location,
    inventory_level,
    reorder_point,
    reorder_quantity,
    supplier_id,
    supplier_lead_time,
    -- customer attributes are stable per customer: fill gaps from their other transactions
    coalesce(customer_age, max(customer_age) over (partition by customer_id)) as customer_age,
    coalesce(customer_gender, max(customer_gender) over (partition by customer_id), 'Unknown') as customer_gender,
    customer_income,
    customer_loyalty_level,
    payment_method,
    promotion_applied,
    promotion_type,
    weather_conditions,
    holiday_indicator,
    -- the raw weekday column is not trusted; derive it from the date
    trim(to_char(transaction_timestamp, 'Day'))                         as weekday,
    stockout_indicator,
    forecasted_demand,
    actual_demand,
    quantity_sold * unit_price                                          as total_amount
from parsed
