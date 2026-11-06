with source as (

    select * from {{ source('olist', 'product_category_translation') }}

),

renamed as (

    select
        trim(product_category_name) as category_name,
        trim(product_category_name_english) as category_name_english
    from source

)

select * from renamed

