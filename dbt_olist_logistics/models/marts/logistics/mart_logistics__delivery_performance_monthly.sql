-- Grain: one row per purchase month and customer state.
with orders as (

    select * from {{ ref('fct_orders') }}

),

customers as (

    select customer_id, state from {{ ref('dim_customers') }}

),

joined as (

    select
        date_trunc('month', orders.purchase_date)::date as purchase_month,
        customers.state as customer_state,
        orders.order_id,
        orders.is_delivered,
        orders.is_late,
        orders.is_severely_late,
        orders.delivery_days,
        orders.estimated_delivery_days,
        orders.delivery_delay_days,
        orders.carrier_transit_days,
        orders.freight_value,
        orders.review_score
    from orders
    inner join customers on orders.customer_id = customers.customer_id

),

final as (

    select
        purchase_month,
        customer_state,
        count(*) as order_count,
        count(*) filter (where is_delivered) as delivered_order_count,
        count(*) filter (where is_late is not null) as orders_with_delivery_date,
        count(*) filter (where is_late) as late_order_count,
        count(*) filter (where is_severely_late) as severely_late_order_count,
        round(
            count(*) filter (where is_late = false)::numeric
            / nullif(count(*) filter (where is_late is not null), 0),
            4
        ) as on_time_delivery_rate,
        round(avg(delivery_days), 2) as avg_delivery_days,
        round(avg(estimated_delivery_days), 2) as avg_estimated_delivery_days,
        round(avg(carrier_transit_days), 2) as avg_carrier_transit_days,
        round(avg(delivery_delay_days) filter (where is_late), 2) as avg_delay_days_when_late,
        round(avg(freight_value), 2) as avg_freight_value,
        round(avg(review_score), 2) as avg_review_score
    from joined
    group by purchase_month, customer_state

)

select * from final

