{{ config(materialized='table') }}

with home as (
    select
        g.*,
        count(*) over (partition by g.game_date) > 1                 as is_doubleheader,
        count(*) over (partition by g.game_date) = 2
            and count(g.attendance) over (partition by g.game_date) = 1
                                                                      as is_single_admission_dh
    from {{ ref('int_games_pregame') }} g
    where g.is_home
      and g.season not in (2020, 2021)
      and not g.is_neutral_site
)

select
    -- keys
    h.game_id,
    h.game_date,
    h.opponent,

    -- game context
    h.season,
    h.game_number,
    h.is_night,
    h.is_home_opener,
    h.is_doubleheader,
    h.is_single_admission_dh,
    h.side_game_seq                         as home_game_seq,

    -- team state before first pitch
    h.pregame_wins,
    h.pregame_losses,
    round(h.pregame_win_pct, 3)             as pregame_win_pct,
    h.pregame_games_behind,
    h.pregame_division_rank,
    h.pregame_streak,
    h.pregame_leverage,
    round(h.last10_win_pct, 3)              as last10_win_pct,
    round(h.rolling5_attendance)::int       as rolling5_attendance,

    -- weather
    w.game_temp_f,
    w.game_precip_in,
    w.game_wind_mph,
    w.game_humidity_pct,
    w.game_cloud_cover_pct,
    w.had_rain,

    -- outcome (for reporting, NOT model features)
    h.is_win,
    h.runs_scored,
    h.runs_allowed,
    h.duration_minutes,

    -- target
    h.attendance

from home h
left join {{ ref('int_game_weather') }} w using (game_id)
-- single-admission doubleheaders: one crowd is recorded on game 2; drop the empty game 1 row
where not (h.is_single_admission_dh and h.attendance is null)
