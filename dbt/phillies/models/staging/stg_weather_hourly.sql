select
    time                              as observed_at,
    time::date                        as weather_date,
    extract(hour from time)::int      as hour,
    temperature_2m                    as temp_f,
    precipitation                     as precip_in,
    wind_speed_10m                    as wind_mph,
    relative_humidity_2m              as humidity_pct,
    cloud_cover                       as cloud_cover_pct
from {{ source('raw', 'weather_hourly') }}
