with customers as (

    select * from {{ ref('stg_olist__customers') }}

),

centroids as (

    select * from {{ ref('int_geolocation__zip_centroids') }}

),

final as (

    select
        customers.customer_id,
        customers.customer_unique_id,
        customers.zip_code_prefix,
        customers.city,
        customers.state,
        centroids.latitude,
        centroids.longitude
    from customers
    left join centroids on customers.zip_code_prefix = centroids.zip_code_prefix

)

select * from final

