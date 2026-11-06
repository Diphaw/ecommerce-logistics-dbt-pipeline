{#-
    Great-circle distance in kilometres between two lat/lng points (haversine formula).
    Returns NULL if any coordinate is NULL.
-#}
{% macro haversine_km(lat1, lng1, lat2, lng2) -%}
    round((
        2 * 6371 * asin(sqrt(
            power(sin(radians(({{ lat2 }} - {{ lat1 }}) / 2)), 2)
            + cos(radians({{ lat1 }})) * cos(radians({{ lat2 }}))
              * power(sin(radians(({{ lng2 }} - {{ lng1 }}) / 2)), 2)
        ))
    )::numeric, 2)
{%- endmacro %}

