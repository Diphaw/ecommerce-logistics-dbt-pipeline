-- One row per order, keeping only the most recent review (orders can be reviewed more than once).
with reviews as (

    select * from {{ ref('stg_olist__order_reviews') }}

),

ranked as (

    select
        order_id,
        review_id,
        review_score,
        created_at as review_created_at,
        answered_at as review_answered_at,
        row_number() over (
            partition by order_id
            order by created_at desc, answered_at desc nulls last, review_id
        ) as review_rank
    from reviews

)

select
    order_id,
    review_id,
    review_score,
    review_created_at,
    review_answered_at
from ranked
where review_rank = 1

