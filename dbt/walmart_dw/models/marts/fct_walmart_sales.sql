with sales as (
    select * from {{ ref('stg_walmart_sales') }}
),

products as (
    select * from {{ ref('dim_product') }}
),

customers as (
    select * from {{ ref('dim_customer') }}
),

stores as (
    select * from {{ ref('dim_store') }}
),

suppliers as (
    select * from {{ ref('dim_supplier') }}
),

dates as (
    select * from {{ ref('dim_date') }}
)

select
    -- Primary Surrogate Key (Grain: 1 sale record)
    md5(concat(s.transaction_id::text, '_', s.product_id::text, '_', s.transaction_timestamp::text)) as sales_key,
    
    -- Degenerate Dimension
    s.transaction_id,
    
    -- Foreign Keys to Dimension Tables
    d.date_key,
    p.product_key,
    c.customer_key,
    st.store_key,
    sp.supplier_key,

    -- Measures (Numeric fields for Aggregation)
    s.quantity_sold,
    s.unit_price,
    s.total_amount,
    s.inventory_level,
    s.reorder_point,
    s.reorder_quantity,
    s.forecasted_demand,
    s.actual_demand,

    -- Contextual Attributes / Degenerate Flags
    s.stockout_indicator,
    s.payment_method,
    s.promotion_applied,
    s.promotion_type,
    s.weather_conditions

from sales s
left join products p  on s.product_id = p.product_id
left join customers c on s.customer_id = c.customer_id
left join stores st   on s.store_id = st.store_id
left join suppliers sp on s.supplier_id = sp.supplier_id
left join dates d     on s.transaction_date = d.full_date
