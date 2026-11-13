from pybaseball import schedule_and_record
from sqlalchemy import create_engine, text

engine = create_engine("postgresql+psycopg://localhost/phillies")

df = schedule_and_record(2025, "PHI")
print(df.head())

with engine.begin() as conn:
    conn.execute(text("CREATE SCHEMA IF NOT EXISTS raw"))

df.to_sql("games_2025", engine, schema="raw", if_exists="replace", index=False)

with engine.connect() as conn:
    print(conn.execute(text("SELECT COUNT(*) FROM raw.games_2025")).scalar())
