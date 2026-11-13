import time

import pandas as pd
import requests
from sqlalchemy import create_engine, text

URL = "https://archive-api.open-meteo.com/v1/archive"
LAT, LON = 39.9061, -75.1665  # Citizens Bank Park
engine = create_engine("postgresql+psycopg://localhost/phillies")

frames = []
for season in range(2015, 2027):
    params = {
        "latitude": LAT,
        "longitude": LON,
        "start_date": f"{season}-03-15",
        "end_date": f"{season}-11-05",
        "hourly": "temperature_2m,precipitation,wind_speed_10m,relative_humidity_2m,cloud_cover",
        "temperature_unit": "fahrenheit",
        "wind_speed_unit": "mph",
        "precipitation_unit": "inch",
        "timezone": "America/New_York",
    }
    r = requests.get(URL, params=params, timeout=60)
    r.raise_for_status()
    df = pd.DataFrame(r.json()["hourly"])
    df["season"] = season
    frames.append(df)
    print(season, len(df), "hours")
    time.sleep(2)

weather = pd.concat(frames, ignore_index=True)
weather["time"] = pd.to_datetime(weather["time"])

with engine.begin() as conn:
    conn.execute(text("CREATE SCHEMA IF NOT EXISTS raw"))
    conn.execute(text("DROP TABLE IF EXISTS raw.weather_hourly CASCADE"))

weather.to_sql("weather_hourly", engine, schema="raw", if_exists="replace", index=False)
print(f"Loaded {len(weather)} rows into raw.weather_hourly")
