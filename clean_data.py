"""
Walmart Sales Data Cleaning Script
DSBA8 Data Warehousing Project
"""

import pandas as pd

def clean_walmart_data(input_file: str = 'Walmart.csv', output_file: str = 'cleaned_walmart.csv'):
    print(f"Loading data from {input_file}...")
    df = pd.read_csv(input_file)
    print(f"Total raw rows: {len(df)}")

    # 1. Trim whitespace on all string columns
    str_cols = df.select_dtypes(include='object').columns
    df[str_cols] = df[str_cols].apply(lambda x: x.str.strip() if hasattr(x, 'str') else x)

    # 2. Handle missing promotion types
    df['promotion_type'] = df['promotion_type'].fillna('No Promotion')

    # 3. Format dates and timestamps
    df['transaction_timestamp'] = pd.to_datetime(df['transaction_date'], format='%m/%d/%Y %H:%M')
    df['transaction_date'] = df['transaction_timestamp'].dt.date

    # 4. Calculate total revenue amount
    df['total_amount'] = (df['quantity_sold'] * df['unit_price']).round(2)

    # 5. Export cleaned dataset
    df.to_csv(output_file, index=False)
    print(f"Data cleaning completed! Saved to {output_file}")

if __name__ == '__main__':
    clean_walmart_data()
