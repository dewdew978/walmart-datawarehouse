with source_data as (
    select * from {{ source('raw', 'raw_walmart_sales') }}
)

select
    transaction_id::integer                                      as transaction_id,
    customer_id::integer                                         as customer_id,
    product_id::integer                                          as product_id,
    trim(product_name)                                           as product_name,
    trim(category)                                               as category,
    quantity_sold::integer                                       as quantity_sold,
    unit_price::numeric(10, 2)                                   as unit_price,
    to_timestamp(transaction_date, 'MM/DD/YYYY HH24:MI')        as transaction_timestamp,
    to_timestamp(transaction_date, 'MM/DD/YYYY HH24:MI')::date  as transaction_date,
    store_id::integer                                            as store_id,
    trim(store_location)                                         as store_location,
    inventory_level::integer                                     as inventory_level,
    reorder_point::integer                                       as reorder_point,
    reorder_quantity::integer                                    as reorder_quantity,
    supplier_id::integer                                         as supplier_id,
    supplier_lead_time::integer                                  as supplier_lead_time,
    customer_age::integer                                        as customer_age,
    trim(customer_gender)                                        as customer_gender,
    customer_income::numeric(12, 2)                              as customer_income,
    trim(customer_loyalty_level)                                 as customer_loyalty_level,
    trim(payment_method)                                         as payment_method,
    promotion_applied::boolean                                   as promotion_applied,
    nullif(trim(promotion_type), 'None')                         as promotion_type,
    trim(weather_conditions)                                     as weather_conditions,
    holiday_indicator::boolean                                   as holiday_indicator,
    trim(weekday)                                                as weekday,
    stockout_indicator::boolean                                  as stockout_indicator,
    forecasted_demand::integer                                   as forecasted_demand,
    actual_demand::integer                                       as actual_demand,
    (quantity_sold::integer * unit_price::numeric(10, 2))        as total_amount
from source_data
