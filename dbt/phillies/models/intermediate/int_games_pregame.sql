with base as (
    select
        g.*,

        -- standing going INTO the game (previous game's after-game values)
        coalesce(lag(wins_to_date)   over w_season, 0)   as pregame_wins,
        coalesce(lag(losses_to_date) over w_season, 0)   as pregame_losses,
        lag(games_behind)          over w_season          as pregame_games_behind,
        lag(division_rank)         over w_season          as pregame_division_rank,
        coalesce(lag(streak)       over w_season, 0)      as pregame_streak,
        lag(championship_leverage) over w_season          as pregame_leverage,

        -- recent form: last 10 games, excluding this one
        avg(is_win::int) over (w_season rows between 10 preceding and 1 preceding)
                                                          as last10_win_pct,

        -- home/away sequence and recent crowds on the same side
        row_number() over w_side                          as side_game_seq,
        avg(attendance) over (w_side rows between 5 preceding and 1 preceding)
                                                          as rolling5_attendance,

        -- calendar
        extract(isodow from game_date)::int               as day_of_week,
        extract(month  from game_date)::int               as month

    from {{ ref('stg_games') }} g
    window
        w_season as (partition by season order by game_date, game_number),
        w_side   as (partition by season, is_home order by game_date, game_number)
)

select
    *,
    pregame_wins::numeric / nullif(pregame_wins + pregame_losses, 0) as pregame_win_pct,
    is_home and side_game_seq = 1                                    as is_home_opener,
    day_of_week in (6, 7)                                            as is_weekend
from base
