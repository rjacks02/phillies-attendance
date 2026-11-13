{{ config(materialized='table') }}

select
    d::date                              as date_day,
    extract(year from d)::int            as year,
    extract(month from d)::int           as month,
    to_char(d, 'Mon')                    as month_name,
    extract(isodow from d)::int          as day_of_week,
    to_char(d, 'Dy')                     as day_name,
    extract(isodow from d) in (6, 7)     as is_weekend
from generate_series('2015-01-01'::date, '2025-12-31'::date, interval '1 day') as d
