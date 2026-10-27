# Issue #2: Grain and Sales Summary Implementation Plan

**Goal:** Complete the four requirements in GitHub issue #2 without changing existing metric results.

**Architecture:** One table, `smt_sales_summary`, reads the sales fact and Date/Product/Store dimensions. `ROLLUP(year, quarter, month_number)` crosses `CUBE(store_location, category)`. Each row carries explicit time/dimension grain and grouping bits. Distinct transaction counts and AOV are computed from fact records at every level.

**Tech stack:** Existing PostgreSQL 16 and dbt 1.8 Docker services.

**Spec:** https://github.com/dewdew978/walmart-datawarehouse/issues/2

## Tasks

- [x] Add reconciliation tests: exactly one grand total; compare every subtotal against independent GROUP BY queries, including missing/extra rows and AOV; enforce grain uniqueness.
- [x] Add the summary model and table materialization; document grain in all 12 model descriptions and summary column tests.
- [x] Add README grain inventory, grouping semantics, roll-up/drill-down queries and BI aggregation rules.
- [x] Run full dbt build/docs, check totals, and prove tests detect corrupted/missing subtotals using rolled-back changes.

## Review focus

- Actual NULL dimension values must remain distinct from omitted dimensions (GROUPING bits).
- Never SUM across subtotal levels or average already-computed AOVs.
- Derive all 16 time/dimension level combinations, not only the grand total.
- Preserve year/quarter context when drilling into month numbers.
- Empty input still has one grand-total row, zero counts/revenue/units and NULL AOV.


## Validation evidence

- Full `dbt build`: 12 models, 80 data tests; 79 tests passed and the existing customer-age warning remained (3 source records); no errors/skips.
- Summary: 324 rows across all 16 level combinations; grand total revenue 77,755,118.16, units 101,502, transactions 50,000, AOV 1,555.10.
- PostgreSQL fixture execution of compiled model verified multi-line transactions, multiple years, real NULL dimensions, summary key uniqueness and empty fact behavior.
- Rolled-back mutations verified detection of wrong revenue, missing subtotal, wrong AOV, duplicate grain and missing grand total. Reconciliation returned zero failures after rollback.
- `dbt docs generate` and `git diff --check` passed.
