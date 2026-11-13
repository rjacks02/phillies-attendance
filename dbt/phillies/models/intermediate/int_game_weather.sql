with games as (
    select game_id, game_date, is_night
    from {{ ref('stg_games') }}
),

weather as (
    select * from {{ ref('stg_weather_hourly') }}
)

select
    g.game_id,
    round(avg(w.temp_f)::numeric, 1)            as game_temp_f,
    round(sum(w.precip_in)::numeric, 2)         as game_precip_in,
    round(avg(w.wind_mph)::numeric, 1)          as game_wind_mph,
    round(avg(w.humidity_pct)::numeric, 0)      as game_humidity_pct,
    round(avg(w.cloud_cover_pct)::numeric, 0)   as game_cloud_cover_pct,
    bool_or(w.precip_in > 0.05)                 as had_rain
from games g
join weather w
    on w.weather_date = g.game_date
   and w.hour between (case when g.is_night then 19 else 13 end)
                  and (case when g.is_night then 21 else 15 end)
group by g.game_id
