-- Create schema and raw table for Walmart sales data
CREATE TABLE IF NOT EXISTS raw_walmart_sales (
    transaction_id         TEXT,
    customer_id            TEXT,
    product_id             TEXT,
    product_name           TEXT,
    category               TEXT,
    quantity_sold          TEXT,
    unit_price             TEXT,
    transaction_date       TEXT,
    store_id               TEXT,
    store_location         TEXT,
    inventory_level        TEXT,
    reorder_point          TEXT,
    reorder_quantity       TEXT,
    supplier_id            TEXT,
    supplier_lead_time     TEXT,
    customer_age           TEXT,
    customer_gender        TEXT,
    customer_income        TEXT,
    customer_loyalty_level TEXT,
    payment_method         TEXT,
    promotion_applied      TEXT,
    promotion_type         TEXT,
    weather_conditions     TEXT,
    holiday_indicator      TEXT,
    weekday                TEXT,
    stockout_indicator     TEXT,
    forecasted_demand      TEXT,
    actual_demand          TEXT
);

-- Copy data directly from the mounted raw_data folder
COPY raw_walmart_sales
FROM '/home/raw_data/Walmart.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ',');
