with source as (
    select * from {{ source('raw', 'games') }}
),

parsed as (
    select
        -- "Saturday, Jun 14 (1)" -> "Jun 14", plus doubleheader game number
        regexp_replace(split_part("Date", ', ', 2), '\s*\(\d\)', '') as month_day,
        coalesce(substring("Date" from '\((\d)\)')::int, 1)           as game_number,
        *
    from source
)

select
    season || '-' || to_char(to_date(month_day || ' ' || season, 'Mon DD YYYY'), 'MMDD')
        || '-' || game_number                                   as game_id,
    to_date(month_day || ' ' || season, 'Mon DD YYYY')          as game_date,
    season,
    game_number,
    "Opp"                                                       as opponent,
    "Home_Away" <> '@'                                          as is_home,
    "D/N" = 'N'                                                 as is_night,

    -- result
    "W/L"                                                       as result,
    "W/L" like 'W%'                                             as is_win,
    "W/L" like '%-wo'                                           as is_walkoff,
    "R"::int                                                    as runs_scored,
    "RA"::int                                                   as runs_allowed,
    ("R" - "RA")::int                                           as run_diff,
    "Inn"::int                                                  as innings,

    -- standing AFTER this game (lag these before modeling)
    split_part("W-L", '-', 1)::int                              as wins_to_date,
    split_part("W-L", '-', 2)::int                              as losses_to_date,
    "Rank"::int                                                 as division_rank,
    case
        when "GB" = 'Tied' then 0
        when "GB" like 'up%' then -regexp_replace("GB", '^up\s*', '')::numeric
        else "GB"::numeric
    end                                                         as games_behind,
    "Streak"                                                    as streak,
    case when "cLI" ~ '^[0-9.]+$' then "cLI"::numeric end       as championship_leverage,

    -- game details
    nullif("Win", '')                                           as winning_pitcher,
    nullif("Loss", '')                                          as losing_pitcher,
    nullif("Save", '')                                          as save_pitcher,
    case when "Time" ~ '^\d+:\d{2}$'
        then split_part("Time", ':', 1)::int * 60 + split_part("Time", ':', 2)::int
    end                                                         as duration_minutes,
    "Attendance"::int                                           as attendance,
    "Orig. Scheduled"                                           as orig_scheduled,
    loaded_at

from parsed
