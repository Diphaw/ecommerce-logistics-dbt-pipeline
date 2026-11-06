select
    seller_id,
    late_delivery_rate,
    cancellation_rate
from {{ ref('mart_logistics__seller_performance') }}
where late_delivery_rate not between 0 and 1
    or cancellation_rate not between 0 and 1

