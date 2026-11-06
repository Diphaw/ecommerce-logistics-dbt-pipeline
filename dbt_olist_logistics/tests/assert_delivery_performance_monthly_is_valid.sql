-- Grain check: (purchase_month, customer_state) must be unique, and rates must lie within [0, 1].
select
    purchase_month,
    customer_state,
    count(*) as row_count
from {{ ref('mart_logistics__delivery_performance_monthly') }}
group by purchase_month, customer_state
having count(*) > 1

union all

select
    purchase_month,
    customer_state,
    1 as row_count
from {{ ref('mart_logistics__delivery_performance_monthly') }}
where on_time_delivery_rate not between 0 and 1

