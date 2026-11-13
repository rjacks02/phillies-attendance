{{ config(materialized='table') }}

select
    opponent,
    team_name,
    league,
    division,
    division = 'NL East' as is_division_rival
from {{ ref('teams') }}
