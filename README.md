# Phillies Home Attendance Analysis (2015–2026)

What drives attendance at Philadelphia Phillies home games? This project builds an end-to-end analytics pipeline, from raw public data to a modeled warehouse and an interactive dashboard, to answer that question.

**[View the interactive dashboard on Tableau Public](https://public.tableau.com/app/profile/rebecca.jackson8757/viz/PhilliesHomeAttendance20152026_/Dashboard)**

## Key findings

Based on 712 home games from 2015 to 2025 (2026 is held out for forecast testing):

- **Season-level demand matters most.** Average attendance nearly doubled, from about 23,500 per game in 2015–2017 to 41,660 in 2025, closely tracking team quality (r ≈ 0.90 with both the current and previous season's win percentage).
- **The pennant race moves crowds.** Games played while leading the division by 5+ drew about 42,300 on average, vs. about 26,200 when 10+ games back.
- **The home opener is a guaranteed sellout,** averaging 44,722 vs. 31,227 for all other games.
- **Weekends beat weeknights.** Saturday and Sunday games outdraw weekday night games by several thousand fans.
- **American League visitors draw more than NL East rivals** (35,247 vs. 30,037 on average), likely because interleague visits are rarer events. Part of this gap reflects timing: AL visits became more frequent in the high-attendance 2023+ seasons.
- **Weather barely matters** between 50°F and 89°F. Only cold games (under 50°F) show a clear dip.
- **2026 attendance fell about 4%** from 2025, mostly early in the season, alongside a weaker record (.540 vs. .590).

## Pipeline

```
Baseball Reference ─┐
Retrosheet ─────────┼─> Python ingestion ─> PostgreSQL (raw) ─> dbt (staging → intermediate → marts) ─> Tableau
Open-Meteo ─────────┘                                                                                ─> Jupyter (EDA)
```

| Layer | Tools | What it does |
|---|---|---|
| Ingestion | Python, pybaseball, requests, pandas | Pulls game logs, venue data, and hourly weather into a `raw` schema |
| Warehouse | PostgreSQL | Stores raw and modeled tables |
| Transformation | dbt | Cleans, types, and models the data into a star schema, with tests |
| Analysis | Jupyter, pandas, matplotlib | Exploratory analysis of attendance drivers |
| Visualization | Tableau | Interactive dashboard with cross-filtering |
| Environment | uv | Reproducible Python environment (`pyproject.toml`, `uv.lock`) |

## Data model

The dbt project (`dbt/phillies/`) is organized in three layers:

| Layer | Models | Purpose |
|---|---|---|
| Staging | `stg_games`, `stg_weather_hourly`, `stg_retrosheet_games` | Clean, typed, renamed source data |
| Intermediate | `int_games_pregame`, `int_game_weather` | Pregame features and per-game weather |
| Marts | `fct_home_games`, `dim_opponent`, `dim_date` | Star schema used by Tableau and the EDA notebook |

`fct_home_games` has one row per ticketed home game, related to `dim_opponent` (league, division, rival flag) and `dim_date` (calendar attributes). dbt tests enforce unique game IDs, non-null attendance, and valid relationships between the fact and dimension tables.

## Data quality decisions

- **No data leakage.** Standings fields in the source (record, games behind, streak) describe the team *after* each game. The pipeline lags them so every feature reflects only what fans knew *before* first pitch.
- **Single-admission doubleheaders.** Baseball Reference records one crowd for both games, on game 2. These are kept as one ticketed event, found through a failing dbt test.
- **Neutral-site games.** Retrosheet park IDs identify home games not played at Citizens Bank Park (such as the 2024 London Series), which are excluded.
- **2020–2021 excluded.** These seasons had no fans or limited capacity due to COVID-19.
- **Dependency pinning.** pandas is pinned below 3.0 for compatibility with pybaseball.

## Repository structure

```
├── ingest/             # Python scripts that load raw data into PostgreSQL
├── dbt/phillies/       # dbt project: sources, models, seeds, tests
├── notebooks/          # Exploratory data analysis
├── docs/               # Tableau workbook (.twbx)
├── data/               # Local data folders (raw data is not committed)
├── pyproject.toml      # Python dependencies
└── uv.lock             # Locked dependency versions
```

## Running it locally

Requirements: [uv](https://docs.astral.sh/uv/) and PostgreSQL.

```bash
# 1. Install dependencies
uv sync

# 2. Create the database
createdb phillies

# 3. Load raw data
uv run python ingest/pull_games.py
uv run python ingest/pull_weather.py
uv run python ingest/pull_retrosheet.py

# 4. Build and test the models
cd dbt/phillies
uv run dbt build --profiles-dir .
```

Update `user` in `dbt/phillies/profiles.yml` to your PostgreSQL username. To explore the analysis, run `uv run jupyter lab` from the project root and open `notebooks/EDA.ipynb`.

## Limitations

- **Attendance is capped at capacity.** Sellouts hide how much demand exceeded available seats.
- **Weather is actual, not forecast.** Fans buy tickets based on the forecast, and rained-out games are not in the data.
- **Small opponent samples.** Most teams visit only a handful of times, so per-team averages are noisy.
- **Venue checks for 2026** will be possible once Retrosheet publishes its 2026 game logs.

## Next steps

- Forecasting model trained on 2015–2025 and tested on the 2026 holdout season
- Rebuild the dashboard in Power BI

## Data sources

- **Baseball Reference**, via the [pybaseball](https://github.com/jldbc/pybaseball) package: game results, standings, and attendance
- **Retrosheet**: venue (park) IDs for each game
- **[Open-Meteo](https://open-meteo.com/)**: historical hourly weather, licensed under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/)

> The information used here was obtained free of charge from and is copyrighted by Retrosheet. Interested parties may contact Retrosheet at [www.retrosheet.org](https://www.retrosheet.org).

## Author

Rebecca Jackson, M.S. Computer Science at Villanova University
