# Walmart | Retail Intelligence

The dashboard was recreated from a three-page reference export. That source PDF
contained rendered charts, not the original saved questions, SQL, dashboard
objects or filter mappings.

`dashboard_queries.sql` contains 15 independent questions in display order, with
suggested chart types and formatting. The existing dataset is synthetic 2024 data.

## Recreate in Metabase

1. Sign in at `http://localhost:33000` using the existing Metabase account.
2. Confirm the connected PostgreSQL database is `walmart_dw`, schema `public`.
3. Create a new collection/dashboard named **Walmart | Retail Intelligence**.
4. For each numbered query, create a SQL question, run it, select the documented
   visualization and save it in that collection. Add the questions to the dashboard.
5. Put the four KPI cards first, City/Promotion next, Monthly Trend full width,
   followed by Income/Payment, the inventory charts, membership charts and Quarter.
6. Verify currency, numeric and percentage formats independently for each chart.

For the latest design, use the four-tab mapping and visualization settings in
`dashboard-design.json`. Database, dashboard and question IDs in that file belong
to the source instance; map them to the IDs on the target instance. It is a design
reference, not a Metabase serialization export or an automatic installer.

## Corrections from the PDF

- Transactions and units are integers, not dollars. AOV has its own currency card.
- Holiday comparison uses a stockout **rate within each day type**, instead of
  the share of stockout events occurring on holiday/normal days.
- Income and forecast variance are recomputed from fact-level observations, not
  unweighted averages of already-aggregated metric rows.
- Weather and membership transitions use categorical bars; transition labels show
  both the starting and ending membership tiers.
- Stockout queries return values in 0..100, while uplift returns a fraction.
  Do not apply the same percentage scaling to both.
- Summary charts select a single time grain and dimension grain. Never total
  all summary rows, which overlap across grouping levels.

## Baseline totals

Expected before applying filters: revenue **77,755,118.16**, transactions **50,000**,
units **101,502**, AOV **1,555.10**. Stockout rates describe recorded sales events,
not all SKU-days. Membership comparisons and promotion comparisons do not establish
causal effects.

Creating the dashboard requires an authenticated Metabase session. These files
do not modify accounts or recover/reset credentials.

## Created dashboard (2026-10-28)

- Local dashboard: http://localhost:33000/dashboard/2-walmart-pdf-recreation
- 15 saved questions, IDs 40 through 54, in Our analytics.
- Current export: `Walmart - Retail Intelligence.pdf` in this directory.
- All 15 SQL queries were checked against PostgreSQL. The saved dashboard was
  checked for missing cards/query errors, and the exported PDF was rendered and
  visually reviewed with all charts present.
- Holiday stockout rates: normal days 3.94%, holidays 22.51%.
- Actual dashboard objects live in the Metabase application database volume;
  these SQL files and the PDF alone are not a full backup of editable dashboards.

## Visual redesign (2026-10-28)

The same local dashboard is now named **Walmart | Retail Intelligence**:
http://localhost:33000/dashboard/2

- **Overview:** four KPI cards, city/promotion comparison, full-width monthly
  revenue, quarterly revenue and a short 2024 insight note.
- **Customers:** membership spending/income and payment mix, with aligned card
  heights and a note explaining the income weighting and revenue denominator.
- **Inventory:** lead-time and holiday stockout rates, signed forecast error and
  a risk interpretation note.
- **Loyalty:** upgrade/control spending, uplift and observational-comparison notes.

All 15 questions retain their IDs (40–54). Titles/axes/legends were shortened,
data labels added and chart colors made consistent. `dashboard-design.json`
records the question queries and visualization settings. Dashboard tabs,
positions and text notes are stored in Metabase itself. All four tabs were
visually checked, with 8/2/3/2 charts respectively and no query errors.

`Walmart - Retail Intelligence.pdf` is the current four-page export (Overview,
Customers, Inventory, Loyalty), with navigation bookmarks. It is the only PDF
kept in the repository. All four pages were rendered and visually checked after
export.
