with bounds as (

    select
        min(purchased_at)::date as start_date,
        max(greatest(purchased_at, estimated_delivery_at, delivered_to_customer_at))::date as end_date
    from {{ ref('stg_olist__orders') }}

),

spine as (

    select generate_series(start_date::timestamp, end_date::timestamp, interval '1 day')::date as date_day
    from bounds

),

final as (

    select
        date_day,
        extract(year from date_day)::int as year,
        extract(quarter from date_day)::int as quarter,
        extract(month from date_day)::int as month,
        to_char(date_day, 'YYYY-MM') as year_month,
        trim(to_char(date_day, 'Month')) as month_name,
        extract(isodow from date_day)::int as iso_day_of_week,
        trim(to_char(date_day, 'Day')) as day_name,
        extract(isodow from date_day) in (6, 7) as is_weekend
    from spine

)

select * from final

