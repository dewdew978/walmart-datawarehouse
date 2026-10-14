"""
Walmart Sales Synthetic Data Generator
DSBA8 Data Warehousing Project

Generates a realistic, reproducible replacement for the original Walmart.csv:
  - Stable master data: each product/store/customer/supplier id has one set of attributes
  - Full calendar year 2024 with seasonality, weekends, US holidays and Black Friday
  - Business relationships the dashboards can surface (promotions lift quantity,
    long supplier lead times and under-forecasting drive stockouts, loyalty tiers
    differ in spend, weather affects store traffic)
  - Optional "dirty" rows (whitespace, casing, missing values, mixed date/price/boolean
    formats, duplicate rows) for the dbt staging layer to clean

Same 28 columns and base formats as the original file, so the raw load is unchanged.
Uses the standard library only.

Usage:
    python generate_data.py                      # 50,000 rows, 2% dirty rate per issue type
    python generate_data.py --dirty-rate 0       # clean output
    python generate_data.py --rows 10000 --seed 7 --out raw_data/sample.csv
"""

import argparse
import collections
import csv
import datetime as dt
import random

COLUMNS = [
    'transaction_id', 'customer_id', 'product_id', 'product_name', 'category', 'quantity_sold',
    'unit_price', 'transaction_date', 'store_id', 'store_location', 'inventory_level', 'reorder_point',
    'reorder_quantity', 'supplier_id', 'supplier_lead_time', 'customer_age', 'customer_gender',
    'customer_income', 'customer_loyalty_level', 'payment_method', 'promotion_applied', 'promotion_type',
    'weather_conditions', 'holiday_indicator', 'weekday', 'stockout_indicator', 'forecasted_demand',
    'actual_demand',
]

YEAR = 2024

# name: (category, min price, max price, number of product ids, popularity, peak months)
PRODUCT_TYPES = {
    'Fridge':          ('Appliances',  400, 2000, 30, 0.6, {6, 7, 8}),
    'Washing Machine': ('Appliances',  350, 1500, 30, 0.5, {3, 4, 5}),
    'TV':              ('Electronics', 250, 2000, 35, 1.0, {2, 11, 12}),
    'Laptop':          ('Electronics', 400, 2000, 35, 1.1, {8, 9}),
    'Smartphone':      ('Electronics', 150, 1300, 40, 1.6, {9, 11, 12}),
    'Tablet':          ('Electronics', 120,  900, 30, 0.9, {8, 11, 12}),
    'Camera':          ('Electronics', 150, 1500, 25, 0.6, {6, 7, 12}),
    'Headphones':      ('Electronics',  30,  400, 40, 1.5, {11, 12}),
}

# city: (traffic factor, weather probabilities by season [Sunny, Cloudy, Rainy, Stormy])
CITIES = {
    'New York, NY':    (1.20, {'winter': (25, 40, 20, 15), 'summer': (45, 25, 20, 10)}),
    'Los Angeles, CA': (1.15, {'winter': (60, 25, 12, 3),  'summer': (80, 15, 4, 1)}),
    'Chicago, IL':     (1.00, {'winter': (20, 40, 15, 25), 'summer': (45, 25, 20, 10)}),
    'Dallas, TX':      (0.95, {'winter': (45, 30, 15, 10), 'summer': (60, 15, 10, 15)}),
    'Miami, FL':       (0.85, {'winter': (60, 25, 12, 3),  'summer': (35, 20, 25, 20)}),
}
WEATHER = ['Sunny', 'Cloudy', 'Rainy', 'Stormy']
WEATHER_TRAFFIC = {'Sunny': 1.0, 'Cloudy': 0.97, 'Rainy': 0.88, 'Stormy': 0.70}

HOLIDAYS = {
    dt.date(2024, 1, 1), dt.date(2024, 1, 15), dt.date(2024, 2, 19), dt.date(2024, 5, 27),
    dt.date(2024, 6, 19), dt.date(2024, 7, 4), dt.date(2024, 9, 2), dt.date(2024, 10, 14),
    dt.date(2024, 11, 11), dt.date(2024, 11, 28), dt.date(2024, 11, 29),  # Thanksgiving, Black Friday
    dt.date(2024, 12, 24), dt.date(2024, 12, 25), dt.date(2024, 12, 31),
}
BLACK_FRIDAY = dt.date(2024, 11, 29)
MONTH_TRAFFIC = {1: .85, 2: .80, 3: .90, 4: .90, 5: .95, 6: 1.0, 7: 1.0, 8: 1.05, 9: .90, 10: .95, 11: 1.30, 12: 1.60}
WEEKDAY_TRAFFIC = {0: .90, 1: .85, 2: .90, 3: .95, 4: 1.10, 5: 1.30, 6: 1.15}  # Monday = 0

LOYALTY_TIERS = ['Bronze', 'Silver', 'Gold', 'Platinum']
LOYALTY_FREQUENCY = {'Bronze': 1.0, 'Silver': 1.5, 'Gold': 2.2, 'Platinum': 3.0}
PAYMENT_METHODS = ['Credit Card', 'Debit Card', 'Cash', 'Digital Wallet']
HOUR_WEIGHTS = {8: 2, 9: 3, 10: 5, 11: 7, 12: 8, 13: 7, 14: 5, 15: 5, 16: 6, 17: 8, 18: 9, 19: 8, 20: 6, 21: 4, 22: 2}


def build_master_data(rng):
    suppliers = {sid: rng.choices(range(1, 11), weights=[3, 6, 8, 9, 9, 8, 6, 4, 3, 2])[0]
                 for sid in rng.sample(range(100, 501), 60)}

    products = []
    product_ids = iter(rng.sample(range(100, 1000), sum(t[3] for t in PRODUCT_TYPES.values())))
    for name, (category, lo, hi, n, popularity, peaks) in PRODUCT_TYPES.items():
        for _ in range(n):
            products.append({
                'product_id': next(product_ids), 'product_name': name, 'category': category,
                'base_price': round(rng.uniform(lo, hi), 2), 'popularity': popularity * rng.uniform(0.5, 1.5),
                'peaks': peaks, 'supplier_id': rng.choice(list(suppliers)),
                'reorder_point': rng.randint(50, 150), 'reorder_quantity': rng.randint(100, 300),
                'base_demand': rng.randint(120, 380),
            })

    cities = list(CITIES)
    stores = [{'store_id': i, 'store_location': cities[(i - 1) % len(cities)], 'traffic': rng.uniform(0.7, 1.3)}
              for i in range(1, 21)]

    customers = []
    for cid in rng.sample(range(1001, 10000), 8000):
        age = int(min(70, max(18, rng.triangular(18, 70, 38))))
        income = min(150000, max(20000, rng.lognormvariate(11.05, 0.35) * (1 + (45 - abs(age - 45)) / 150)))
        tier_score = (income - 20000) / 130000 + rng.gauss(0, 0.2)
        tier = LOYALTY_TIERS[min(3, max(0, int(tier_score * 4)))]
        customers.append({
            'customer_id': cid, 'customer_age': age,
            'customer_gender': rng.choices(['Male', 'Female', 'Other'], weights=[48, 48, 4])[0],
            'customer_income': round(income, 2), 'customer_loyalty_level': tier,
            'home_store': rng.choice(stores)['store_id'],
        })
    return suppliers, products, stores, customers


def build_calendar(rng):
    days = [dt.date(YEAR, 1, 1) + dt.timedelta(d) for d in range(366)]
    weather = {}
    for d in days:
        season = 'summer' if 5 <= d.month <= 10 else 'winter'
        for city, (_, probs) in CITIES.items():
            weather[(d, city)] = rng.choices(WEATHER, weights=probs[season])[0]
    return days, weather


def day_traffic(d):
    w = MONTH_TRAFFIC[d.month] * WEEKDAY_TRAFFIC[d.weekday()]
    if d == BLACK_FRIDAY:
        w *= 3.0
    elif d == dt.date(YEAR, 12, 25):
        w *= 0.3
    elif d in HOLIDAYS:
        w *= 1.5
    return w


def generate_rows(rng, n_rows):
    suppliers, products, stores, customers = build_master_data(rng)
    days, weather = build_calendar(rng)
    city_traffic = {c: v[0] for c, v in CITIES.items()}

    slots = [(d, s) for d in days for s in stores]
    slot_weights = [day_traffic(d) * s['traffic'] * city_traffic[s['store_location']]
                    * WEATHER_TRAFFIC[weather[(d, s['store_location'])]] for d, s in slots]

    by_home = collections.defaultdict(list)
    for c in customers:
        by_home[c['home_store']].append(c)
    freq = lambda pool: [LOYALTY_FREQUENCY[c['customer_loyalty_level']] for c in pool]
    all_freq = freq(customers)
    home_freq = {sid: freq(pool) for sid, pool in by_home.items()}

    product_weights = {m: [p['popularity'] * (1.8 if m in p['peaks'] else 1.0) for p in products]
                       for m in range(1, 13)}
    hours, hour_w = list(HOUR_WEIGHTS), list(HOUR_WEIGHTS.values())

    rows = []
    for d, store in rng.choices(slots, weights=slot_weights, k=n_rows):
        city = store['store_location']
        holiday = d in HOLIDAYS
        if rng.random() < 0.85 and by_home[store['store_id']]:
            customer = rng.choices(by_home[store['store_id']], weights=home_freq[store['store_id']])[0]
        else:
            customer = rng.choices(customers, weights=all_freq)[0]
        product = rng.choices(products, weights=product_weights[d.month])[0]
        lead_time = suppliers[product['supplier_id']]

        promo_prob = 0.45 if holiday else 0.35 if d.month in (11, 12) else 0.18
        promotion_type = rng.choices(['BOGO', 'Percentage Discount'], weights=[45, 55])[0] \
            if rng.random() < promo_prob else 'None'

        quantity = rng.choices([1, 2, 3, 4, 5], weights=[45, 28, 15, 8, 4])[0]
        if product['category'] == 'Appliances':
            quantity = 1 if rng.random() < 0.8 else 2
        if promotion_type == 'BOGO':
            quantity = min(5, max(2, quantity + 1))
        elif promotion_type == 'Percentage Discount' and rng.random() < 0.4:
            quantity = min(5, quantity + 1)

        unit_price = product['base_price'] * rng.uniform(0.97, 1.03)
        if promotion_type == 'Percentage Discount':
            unit_price *= 1 - rng.choice([0.10, 0.15, 0.20, 0.25, 0.30])

        forecast = product['base_demand'] * (1.25 if d.month in product['peaks'] else 1.0)
        forecast = int(min(500, max(100, forecast * rng.uniform(0.9, 1.1))))
        demand_shift = 1 + rng.gauss(0, 0.08)
        if d == BLACK_FRIDAY:
            demand_shift += 0.35
        elif holiday:
            demand_shift += 0.12
        if promotion_type != 'None':
            demand_shift += 0.10
        if weather[(d, city)] == 'Stormy':
            demand_shift -= 0.10
        actual = int(min(600, max(80, forecast * demand_shift)))

        stock_mean = 300 - 14 * lead_time - (60 if d.month in (11, 12) else 0) - 1.5 * (actual - forecast)
        inventory = int(min(500, max(0, rng.gauss(stock_mean, 90))))

        ts = dt.datetime(d.year, d.month, d.day, rng.choices(hours, weights=hour_w)[0], rng.randint(0, 59))
        payment = rng.choices(PAYMENT_METHODS, weights=[30, 25, 25 if customer['customer_age'] > 45 else 10,
                                                         10 if customer['customer_age'] > 45 else 30])[0]
        rows.append({
            'customer_id': customer['customer_id'], 'product_id': product['product_id'],
            'product_name': product['product_name'], 'category': product['category'],
            'quantity_sold': quantity, 'unit_price': f"{unit_price:.2f}", 'ts': ts,
            'store_id': store['store_id'], 'store_location': city, 'inventory_level': inventory,
            'reorder_point': product['reorder_point'], 'reorder_quantity': product['reorder_quantity'],
            'supplier_id': product['supplier_id'], 'supplier_lead_time': lead_time,
            'customer_age': customer['customer_age'], 'customer_gender': customer['customer_gender'],
            'customer_income': f"{customer['customer_income']:.2f}",
            'customer_loyalty_level': customer['customer_loyalty_level'], 'payment_method': payment,
            'promotion_applied': promotion_type != 'None', 'promotion_type': promotion_type,
            'weather_conditions': weather[(d, city)], 'holiday_indicator': holiday,
            'weekday': d.strftime('%A'), 'stockout_indicator': inventory < 20,
            'forecasted_demand': forecast, 'actual_demand': actual,
        })

    rows.sort(key=lambda r: r['ts'])
    for i, r in enumerate(rows, start=1):
        r['transaction_id'] = i
        r['transaction_date'] = f"{r['ts'].month}/{r['ts'].day}/{r['ts'].year} {r['ts'].hour}:{r['ts'].minute:02d}"
        for col in ('promotion_applied', 'holiday_indicator', 'stockout_indicator'):
            r[col] = 'TRUE' if r[col] else 'FALSE'
        del r['ts']
    return rows


def inject_dirty_data(rng, rows, rate):
    """Apply each issue type independently to ~rate of rows. Returns rows and per-issue counts."""
    counts = collections.Counter()

    def affected():
        return rng.sample(range(len(rows)), int(len(rows) * rate))

    for i in affected():  # stray whitespace
        col = rng.choice(['product_name', 'store_location', 'category', 'payment_method', 'customer_loyalty_level'])
        rows[i][col] = rng.choice(['  ', ' ', '\t']) + rows[i][col] + rng.choice(['', ' ', '   '])
        counts['whitespace'] += 1
    for i in affected():  # inconsistent casing
        col = rng.choice(['store_location', 'category', 'payment_method', 'customer_loyalty_level', 'customer_gender'])
        rows[i][col] = rng.choice([str.lower, str.upper])(rows[i][col])
        counts['casing'] += 1
    for i in affected():  # inconsistent "City, ST" separator
        city, state = rows[i]['store_location'].split(', ')
        rows[i]['store_location'] = rng.choice([f"{city},{state}", f"{city} ,{state}", f"{city} ,  {state}"])
        counts['location_separator'] += 1
    for i in affected():  # missing values
        col = rng.choice(['customer_gender', 'customer_age', 'promotion_type'])
        if col == 'promotion_type' and rows[i]['promotion_type'] != 'None':
            continue
        rows[i][col] = ''
        counts[f'missing_{col}'] += 1
    for i in affected():  # ISO timestamp instead of M/D/YYYY H:MM
        ts = dt.datetime.strptime(rows[i]['transaction_date'], '%m/%d/%Y %H:%M')
        rows[i]['transaction_date'] = ts.strftime('%Y-%m-%d %H:%M:%S')
        counts['iso_date'] += 1
    for i in affected():  # currency-formatted price
        rows[i]['unit_price'] = f"${float(rows[i]['unit_price']):,.2f}"
        counts['currency_price'] += 1
    for i in affected():  # alternative boolean spellings
        col = rng.choice(['promotion_applied', 'holiday_indicator', 'stockout_indicator'])
        true_, false_ = rng.choice([('Yes', 'No'), ('1', '0'), ('true', 'false'), ('Y', 'N')])
        rows[i][col] = true_ if rows[i][col] == 'TRUE' else false_
        counts['boolean_format'] += 1

    dup_idx = set(rng.sample(range(len(rows)), int(len(rows) * rate / 2)))  # exact duplicate rows
    out = []
    for i, r in enumerate(rows):
        out.append(r)
        if i in dup_idx:
            out.append(dict(r))
            counts['duplicate_rows'] += 1
    return out, counts


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('--rows', type=int, default=50000)
    parser.add_argument('--seed', type=int, default=42)
    parser.add_argument('--dirty-rate', type=float, default=0.02, help='share of rows per dirty-data issue type')
    parser.add_argument('--out', default='raw_data/walmart_sales_v2.csv')
    args = parser.parse_args()

    rng = random.Random(args.seed)
    rows = generate_rows(rng, args.rows)
    counts = collections.Counter()
    if args.dirty_rate > 0:
        rows, counts = inject_dirty_data(rng, rows, args.dirty_rate)

    with open(args.out, 'w', encoding='utf-8', newline='') as f:
        writer = csv.DictWriter(f, fieldnames=COLUMNS, lineterminator='\n')
        writer.writeheader()
        writer.writerows(rows)

    print(f"Wrote {len(rows):,} rows ({args.rows:,} transactions) to {args.out}")
    for issue, n in sorted(counts.items()):
        print(f"  dirty {issue:24} {n:>6,}")


if __name__ == '__main__':
    main()
