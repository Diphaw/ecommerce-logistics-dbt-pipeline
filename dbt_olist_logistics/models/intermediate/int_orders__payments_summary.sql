with payments as (

    select * from {{ ref('stg_olist__order_payments') }}

),

primary_payment as (

    select
        order_id,
        payment_type as primary_payment_type
    from (
        select
            order_id,
            payment_type,
            row_number() over (
                partition by order_id
                order by payment_value desc, payment_sequence_number
            ) as payment_rank
        from payments
    ) as ranked
    where payment_rank = 1

),

totals as (

    select
        order_id,
        sum(payment_value) as total_payment_value,
        count(*) as payment_count,
        max(installments) as max_installments
    from payments
    group by order_id

),

joined as (

    select
        totals.order_id,
        totals.total_payment_value,
        totals.payment_count,
        totals.max_installments,
        primary_payment.primary_payment_type
    from totals
    inner join primary_payment on totals.order_id = primary_payment.order_id

)

select * from joined

