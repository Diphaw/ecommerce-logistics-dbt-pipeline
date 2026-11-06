with orders as (

    select * from {{ ref('stg_olist__orders') }}

),

items as (

    select * from {{ ref('int_orders__items_summary') }}

),

payments as (

    select * from {{ ref('int_orders__payments_summary') }}

),

reviews as (

    select * from {{ ref('int_orders__latest_review') }}

),

joined as (

    select
        orders.order_id,
        orders.customer_id,
        orders.order_status,
        orders.purchased_at::date as purchase_date,
        orders.purchased_at,
        orders.approved_at,
        orders.handed_to_carrier_at,
        orders.delivered_to_customer_at,
        orders.estimated_delivery_at,

        coalesce(items.item_count, 0) as item_count,
        coalesce(items.seller_count, 0) as seller_count,
        coalesce(items.items_value, 0) as items_value,
        coalesce(items.freight_value, 0) as freight_value,
        coalesce(payments.total_payment_value, 0) as total_payment_value,
        payments.primary_payment_type,
        payments.max_installments,
        reviews.review_score,

        orders.order_status = 'delivered'
            and orders.delivered_to_customer_at is not null as is_delivered,

        {{ hours_between('orders.purchased_at', 'orders.approved_at') }} as approval_hours,
        {{ days_between('orders.approved_at', 'orders.handed_to_carrier_at') }} as seller_handling_days,
        {{ days_between('orders.handed_to_carrier_at', 'orders.delivered_to_customer_at') }} as carrier_transit_days,
        {{ days_between('orders.purchased_at', 'orders.delivered_to_customer_at') }} as delivery_days,
        {{ days_between('orders.purchased_at', 'orders.estimated_delivery_at') }} as estimated_delivery_days,

        -- Whole calendar days past the estimate (negative = early). Estimates are date-only.
        orders.delivered_to_customer_at::date - orders.estimated_delivery_at::date as delivery_delay_days

    from orders
    left join items on orders.order_id = items.order_id
    left join payments on orders.order_id = payments.order_id
    left join reviews on orders.order_id = reviews.order_id

),

final as (

    select
        *,
        delivery_delay_days > 0 as is_late,
        delivery_delay_days > {{ var('severe_delay_threshold_days') }} as is_severely_late
    from joined

)

select * from final

