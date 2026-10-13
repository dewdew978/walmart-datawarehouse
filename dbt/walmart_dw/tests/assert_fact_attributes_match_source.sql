-- Every fact row must resolve to dimension members whose attributes match the
-- source transaction. Returns mismatched rows (test passes when empty).
select
    s.transaction_id
from {{ ref('stg_walmart_sales') }} s
join {{ ref('fct_walmart_sales') }} f on f.transaction_id = s.transaction_id
join {{ ref('dim_product') }}  p  on f.product_key  = p.product_key
join {{ ref('dim_store') }}    st on f.store_key    = st.store_key
join {{ ref('dim_customer') }} c  on f.customer_key = c.customer_key
join {{ ref('dim_supplier') }} sp on f.supplier_key = sp.supplier_key
where s.category               <> p.category
   or s.product_name           <> p.product_name
   or s.store_location         <> st.store_location
   or s.customer_loyalty_level <> c.customer_loyalty_level
   or s.supplier_lead_time     <> sp.supplier_lead_time
