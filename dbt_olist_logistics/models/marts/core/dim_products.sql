with products as (

    select * from {{ ref('stg_olist__products') }}

),

translations as (

    select * from {{ ref('stg_olist__product_category_translation') }}

),

final as (

    select
        products.product_id,
        products.category_name,
        -- Fall back to the Portuguese name when untranslated, and 'unknown' when uncategorised.
        coalesce(translations.category_name_english, products.category_name, 'unknown') as category_name_english,
        products.name_length,
        products.description_length,
        products.photos_qty,
        products.weight_g,
        products.length_cm,
        products.height_cm,
        products.width_cm,
        products.length_cm * products.height_cm * products.width_cm as volume_cm3
    from products
    left join translations on products.category_name = translations.category_name

)

select * from final

