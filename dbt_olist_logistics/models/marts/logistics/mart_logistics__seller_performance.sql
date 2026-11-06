with order_items as (

    select * from {{ ref('fct_order_items') }}

),

orders as (

    select * from {{ ref('fct_orders') }}

),

sellers as (

    select * from {{ ref('dim_sellers') }}

),

seller_orders as (

    -- Collapse items to (seller, order) so order-level metrics are not double counted.
    select
        seller_id,
        order_id,
        sum(price) as gross_merchandise_value,
        sum(freight_value) as freight_value,
        avg(seller_to_customer_distance_km) as avg_distance_km
    from order_items
    group by seller_id, order_id

),

seller_order_details as (

    select
        seller_orders.seller_id,
        seller_orders.order_id,
        seller_orders.gross_merchandise_value,
        seller_orders.freight_value,
        seller_orders.avg_distance_km,
        orders.order_status,
        orders.is_delivered,
        orders.is_late,
        orders.delivery_days,
        orders.seller_handling_days,
        orders.review_score
    from seller_orders
    inner join orders on seller_orders.order_id = orders.order_id

),

aggregated as (

    select
        seller_id,
        count(*) as order_count,
        count(*) filter (where is_delivered) as delivered_order_count,
        count(*) filter (where order_status = 'canceled') as canceled_order_count,
        sum(gross_merchandise_value) as gross_merchandise_value,
        sum(freight_value) as freight_value,
        round(avg(gross_merchandise_value), 2) as avg_order_value,
        round(avg(avg_distance_km)::numeric, 2) as avg_distance_km,
        round(avg(delivery_days), 2) as avg_delivery_days,
        round(avg(seller_handling_days), 2) as avg_seller_handling_days,
        round(avg(review_score), 2) as avg_review_score,
        count(*) filter (where is_late is not null) as orders_with_delivery_date,
        count(*) filter (where is_late) as late_order_count
    from seller_order_details
    group by seller_id

),

final as (

    select
        sellers.seller_id,
        sellers.city as seller_city,
        sellers.state as seller_state,
        aggregated.order_count,
        aggregated.delivered_order_count,
        aggregated.canceled_order_count,
        aggregated.gross_merchandise_value,
        aggregated.freight_value,
        aggregated.avg_order_value,
        aggregated.avg_distance_km,
        aggregated.avg_delivery_days,
        aggregated.avg_seller_handling_days,
        aggregated.avg_review_score,
        aggregated.late_order_count,
        round(
            aggregated.late_order_count::numeric
            / nullif(aggregated.orders_with_delivery_date, 0),
            4
        ) as late_delivery_rate,
        round(
            aggregated.canceled_order_count::numeric / nullif(aggregated.order_count, 0),
            4
        ) as cancellation_rate
    from aggregated
    inner join sellers on aggregated.seller_id = sellers.seller_id

)

select * from final

