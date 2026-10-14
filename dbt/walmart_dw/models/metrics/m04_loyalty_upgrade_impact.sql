-- Do customers spend more after a loyalty upgrade?
-- Compares upgraded customers' spend per 30 days after their upgrade with a control group:
-- the average never-upgraded customer of the same starting tier over the same window.
--
-- Why only the post-upgrade window: the change date is derived from transactions (first
-- purchase seen in the new tier), so
--   * the window starts with a guaranteed purchase -> that revealing purchase is excluded;
--     the purchases after it are an unbiased sample of post-upgrade behaviour
--   * the pre-upgrade window is biased (it must contain a purchase, and it absorbs the
--     purchase-free gap between the real upgrade and the first observed new-tier purchase)
-- Comparing against the control over the same window also removes seasonality (Nov-Dec peak).
with upgrades as (
    select
        old_v.customer_id,
        old_v.customer_loyalty_level  as from_tier,
        new_v.customer_loyalty_level  as to_tier,
        new_v.version_number          as to_version,
        new_v.valid_from              as upgraded_at
    from {{ ref('dim_customer') }} old_v
    join {{ ref('dim_customer') }} new_v
        on  new_v.customer_id    = old_v.customer_id
        and new_v.version_number = old_v.version_number + 1
),

sales as (
    select
        c.customer_id,
        c.version_number,
        d.full_date,
        f.total_amount,
        row_number() over (
            partition by c.customer_id, c.version_number
            order by d.full_date, f.transaction_id
        ) as nth_in_version
    from {{ ref('fct_walmart_sales') }} f
    join {{ ref('dim_customer') }} c on f.customer_key = c.customer_key
    join {{ ref('dim_date') }} d     on f.date_key = d.date_key
),

-- Control group: customers with a single version (never changed tier)
stable_customers as (
    select customer_id, min(customer_loyalty_level) as tier
    from {{ ref('dim_customer') }}
    group by customer_id
    having count(*) = 1
),

control_daily as (
    select
        sc.tier,
        s.full_date,
        sum(s.total_amount) / max(tier_size.customers) as spend_per_customer
    from sales s
    join stable_customers sc on sc.customer_id = s.customer_id
    join (select tier, count(*) as customers from stable_customers group by tier) tier_size
        on tier_size.tier = sc.tier
    group by sc.tier, s.full_date
),

per_customer as (
    select
        u.from_tier,
        u.to_tier,
        u.customer_id,
        date '2025-01-01' - u.upgraded_at::date                                     as days_after,
        (select coalesce(sum(s.total_amount), 0) from sales s
          where s.customer_id = u.customer_id
            and s.version_number = u.to_version
            and s.nth_in_version > 1)                                                as spent_after,
        (select coalesce(sum(cd.spend_per_customer), 0) from control_daily cd
          where cd.tier = u.from_tier and cd.full_date >= u.upgraded_at::date)      as control_spent_after
    from upgrades u
)

select
    from_tier,
    to_tier,
    count(*)                                                                as upgraded_customers,
    round(sum(spent_after)         / nullif(sum(days_after), 0) * 30, 2)    as spend_per_30d_after_upgrade,
    round(sum(control_spent_after) / nullif(sum(days_after), 0) * 30, 2)    as control_spend_per_30d,
    round(sum(spent_after) / nullif(sum(control_spent_after), 0) - 1, 3)    as uplift_vs_control
from per_customer
group by from_tier, to_tier
