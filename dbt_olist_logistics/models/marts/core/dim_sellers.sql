with sellers as (

    select * from {{ ref('stg_olist__sellers') }}

),

centroids as (

    select * from {{ ref('int_geolocation__zip_centroids') }}

),

final as (

    select
        sellers.seller_id,
        sellers.zip_code_prefix,
        sellers.city,
        sellers.state,
        centroids.latitude,
        centroids.longitude
    from sellers
    left join centroids on sellers.zip_code_prefix = centroids.zip_code_prefix

)

select * from final

