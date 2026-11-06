with items as (

    select * from {{ ref('stg_olist__order_items') }}

),

orders as (

    select order_id, customer_id from {{ ref('stg_olist__orders') }}

),

customers as (

    select customer_id, zip_code_prefix from {{ ref('stg_olist__customers') }}

),

sellers as (

    select seller_id, zip_code_prefix from {{ ref('stg_olist__sellers') }}

),

centroids as (

    select * from {{ ref('int_geolocation__zip_centroids') }}

),

enriched as (

    select
        items.order_item_key,
        items.order_id,
        items.seller_id,
        orders.customer_id,
        customers.zip_code_prefix as customer_zip_code_prefix,
        sellers.zip_code_prefix as seller_zip_code_prefix,
        {{ haversine_km(
            'seller_geo.latitude', 'seller_geo.longitude',
            'customer_geo.latitude', 'customer_geo.longitude'
        ) }} as seller_to_customer_distance_km
    from items
    inner join orders on items.order_id = orders.order_id
    inner join customers on orders.customer_id = customers.customer_id
    inner join sellers on items.seller_id = sellers.seller_id
    left join centroids as customer_geo on customers.zip_code_prefix = customer_geo.zip_code_prefix
    left join centroids as seller_geo on sellers.zip_code_prefix = seller_geo.zip_code_prefix

)

select * from enriched

