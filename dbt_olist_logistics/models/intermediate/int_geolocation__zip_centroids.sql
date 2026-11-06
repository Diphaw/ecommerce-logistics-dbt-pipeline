with geolocation as (

    select * from {{ ref('stg_olist__geolocation') }}

),

centroids as (

    select
        zip_code_prefix,
        avg(latitude) as latitude,
        avg(longitude) as longitude,
        mode() within group (order by state) as state,
        count(*) as sample_size
    from geolocation
    group by zip_code_prefix

)

select * from centroids

