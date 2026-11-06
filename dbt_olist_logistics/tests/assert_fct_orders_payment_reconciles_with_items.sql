-- Payments should reconcile with items + freight. Small gaps exist upstream (vouchers, rounding),
-- so this surfaces large mismatches as a warning rather than failing the build.
{{ config(severity='warn') }}

select
    order_id,
    items_value + freight_value as expected_value,
    total_payment_value
from {{ ref('fct_orders') }}
where item_count > 0
    and abs(total_payment_value - (items_value + freight_value)) > 1

