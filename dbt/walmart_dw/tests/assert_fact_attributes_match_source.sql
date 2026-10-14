-- Every fact row must resolve to dimension members whose attributes match the
-- source transaction. Returns mismatched rows (test passes when empty).
-- Both sides are materialized first so Postgres hash-joins them on transaction_id.
with source_rows as materialized (
    select transaction_id, product_name, category, store_location, customer_loyalty_level, supplier_lead_time
    from {{ ref('stg_walmart_sales') }}
),

fact_rows as materialized (
    select
        f.transaction_id,
        p.product_name,
        p.category,
        st.store_location,
        c.customer_loyalty_level,
        sp.supplier_lead_time
    from {{ ref('fct_walmart_sales') }} f
    join {{ ref('dim_product') }}  p  on f.product_key  = p.product_key
    join {{ ref('dim_store') }}    st on f.store_key    = st.store_key
    join {{ ref('dim_customer') }} c  on f.customer_key = c.customer_key
    join {{ ref('dim_supplier') }} sp on f.supplier_key = sp.supplier_key
)

select s.transaction_id
from source_rows s
join fact_rows f on f.transaction_id = s.transaction_id
where s.category               <> f.category
   or s.product_name           <> f.product_name
   or s.store_location         <> f.store_location
   or s.customer_loyalty_level <> f.customer_loyalty_level
   or s.supplier_lead_time     <> f.supplier_lead_time
