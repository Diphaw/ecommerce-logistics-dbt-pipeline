{#-
    Elapsed time between two timestamps, expressed in days (rounded to 2 decimals).
    Positive when `end_ts` is after `start_ts`. NULL if either input is NULL.
-#}
{% macro days_between(start_ts, end_ts) -%}
    round((extract(epoch from ({{ end_ts }} - {{ start_ts }})) / 86400.0)::numeric, 2)
{%- endmacro %}

{#- Same as `days_between`, expressed in hours. -#}
{% macro hours_between(start_ts, end_ts) -%}
    round((extract(epoch from ({{ end_ts }} - {{ start_ts }})) / 3600.0)::numeric, 2)
{%- endmacro %}

