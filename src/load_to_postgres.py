from pathlib import Path
import os

import pandas as pd
from dotenv import load_dotenv
from sqlalchemy import create_engine, text


BASE_DIR = Path(__file__).resolve().parents[1]
DATA_DIR = BASE_DIR / "data" / "generated"
SQL_DIR = BASE_DIR / "sql"

load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL")

if not DATABASE_URL:
    raise RuntimeError(
        "DATABASE_URL is not configured. "
        "Create a .env file based on .env.example."
    )


engine = create_engine(
    DATABASE_URL,
    pool_pre_ping=True,
)


def execute_sql_file(path: Path) -> None:
    sql = path.read_text(
        encoding="utf-8"
    )

    with engine.begin() as connection:
        connection.execute(
            text(sql)
        )


def load_csv(
    filename: str,
    table_name: str,
) -> None:

    file_path = DATA_DIR / filename

    if not file_path.exists():
        raise FileNotFoundError(
            f"Missing generated dataset: {file_path}"
        )

    DATE_COLUMNS = {
        "customers.csv": ["created_date"],
        "applications.csv": ["application_date"],
        "transactions.csv": ["transaction_date"],
        "devices.csv": [],
    }
    
    dataframe = pd.read_csv(
        file_path,
        parse_dates=DATE_COLUMNS.get(filename, [])
    )

    print(
        f"Loading {filename}: "
        f"{len(dataframe):,} rows"
    )

    dataframe.to_sql(
        name=table_name,
        con=engine,
        schema="bronze",
        if_exists="append",
        index=False,
        chunksize=5_000,
        method="multi",
    )


def main():
    print("Creating Bronze schema...")

    execute_sql_file(
        SQL_DIR / "01_bronze_schema.sql"
    )

    print("Loading synthetic datasets...")

    load_csv(
        "devices.csv",
        "devices",
    )

    load_csv(
        "customers.csv",
        "customers",
    )

    load_csv(
        "applications.csv",
        "applications",
    )

    load_csv(
        "transactions.csv",
        "transactions",
    )

    print(
        "Bronze data load completed successfully."
    )


if __name__ == "__main__":
    main()
