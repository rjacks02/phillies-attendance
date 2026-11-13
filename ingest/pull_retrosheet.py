"""Retrosheet game logs: venue (park ID) for every Phillies game.

The information used here was obtained free of charge from and is copyrighted
by Retrosheet. Interested parties may contact Retrosheet at www.retrosheet.org.
"""
import io
import time
import zipfile

import pandas as pd
import requests
from sqlalchemy import create_engine, text

URL = "https://www.retrosheet.org/gamelogs/gl{season}.zip"
# Retrosheet game log field positions (0-indexed); the file has no header
COLS = {
    0: "date",
    1: "game_num",
    3: "visiting_team",
    6: "home_team",
    12: "day_night",
    16: "park_id",
    17: "attendance",
}

engine = create_engine("postgresql+psycopg://localhost/phillies")

frames = []
for season in range(2015, 2027):
    r = requests.get(URL.format(season=season), timeout=60)
    if r.status_code == 404:
        print(f"{season}: not published, skipping")
        continue
    r.raise_for_status()
    with zipfile.ZipFile(io.BytesIO(r.content)) as z:
        name = next(n for n in z.namelist() if n.upper().endswith(".TXT"))
        df = pd.read_csv(z.open(name), header=None, usecols=list(COLS), dtype=str)
    df = df.rename(columns=COLS)
    df = df[(df["home_team"] == "PHI") | (df["visiting_team"] == "PHI")]
    df["season"] = season
    frames.append(df)
    print(season, len(df), "Phillies games")
    time.sleep(1)

logs = pd.concat(frames, ignore_index=True)

with engine.begin() as conn:
    conn.execute(text("CREATE SCHEMA IF NOT EXISTS raw"))
    conn.execute(text("DROP TABLE IF EXISTS raw.retrosheet_gamelogs CASCADE"))

logs.to_sql("retrosheet_gamelogs", engine, schema="raw", if_exists="replace", index=False)
print(f"Loaded {len(logs)} rows into raw.retrosheet_gamelogs")
