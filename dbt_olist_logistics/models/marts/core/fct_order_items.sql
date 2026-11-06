-- Grain: one row per order item.
with items as (

    select * from {{ ref('stg_olist__order_items') }}

),

enriched as (

    select * from {{ ref('int_order_items__enriched') }}

),

orders as (

    select * from {{ ref('fct_orders') }}

),

final as (

    select
        items.order_item_key,
        items.order_id,
        items.order_item_number,
        items.product_id,
        items.seller_id,
        orders.customer_id,
        orders.order_status,
        orders.purchase_date,
        items.shipping_limit_at,
        items.price,
        items.freight_value,
        items.price + items.freight_value as item_total_value,
        enriched.seller_to_customer_distance_km,
        orders.delivery_days,
        orders.is_late
    from items
    inner join orders on items.order_id = orders.order_id
    left join enriched on items.order_item_key = enriched.order_item_key

)

select * from final

