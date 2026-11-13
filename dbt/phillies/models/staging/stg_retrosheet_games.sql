-- Phillies home games from Retrosheet, keyed to match stg_games.game_id
select
    season || '-' || substring(date, 5, 4) || '-'
        || case when game_num = '0' then '1' else game_num end   as game_id,
    to_date(date, 'YYYYMMDD')                                    as game_date,
    visiting_team,
    park_id,
    nullif(attendance, '')::int                                  as retro_attendance
from {{ source('raw', 'retrosheet_gamelogs') }}
where home_team = 'PHI'
