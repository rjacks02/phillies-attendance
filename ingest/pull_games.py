import time
from datetime import datetime, timezone

import pandas as pd
from pybaseball import schedule_and_record
from sqlalchemy import create_engine, text

SEASONS = range(2015, 2026)
engine = create_engine("postgresql+psycopg://localhost/phillies")

frames = []
for season in SEASONS:
    print(f"Pulling {season}...")
    df = schedule_and_record(season, "PHI")
    df["season"] = season
    frames.append(df)
    time.sleep(5)  # be polite to Baseball Reference

games = pd.concat(frames, ignore_index=True)
games["loaded_at"] = datetime.now(timezone.utc)

with engine.begin() as conn:
    conn.execute(text("CREATE SCHEMA IF NOT EXISTS raw"))
    conn.execute(text("DROP TABLE IF EXISTS raw.games_2025"))

games.to_sql("games", engine, schema="raw", if_exists="replace", index=False)
print(f"Loaded {len(games)} rows into raw.games")
