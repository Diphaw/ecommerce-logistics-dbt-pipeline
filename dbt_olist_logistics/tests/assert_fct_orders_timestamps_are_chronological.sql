-- Delivery milestones must be chronological. Known upstream anomalies exist, so warn only.
{{ config(severity='warn') }}

select
    order_id,
    purchased_at,
    handed_to_carrier_at,
    delivered_to_customer_at
from {{ ref('fct_orders') }}
where delivered_to_customer_at < purchased_at
    or handed_to_carrier_at < purchased_at
    or delivered_to_customer_at < handed_to_carrier_at

