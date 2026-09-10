from pathlib import Path
import os
import subprocess
import sys

import sqlparse
from dotenv import load_dotenv
from sqlalchemy import create_engine, text


BASE_DIR = Path(__file__).resolve().parents[1]
SQL_DIR = BASE_DIR / "sql"

load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL")

if not DATABASE_URL:
    raise RuntimeError(
        "DATABASE_URL is not configured."
    )

engine = create_engine(
    DATABASE_URL,
    pool_pre_ping=True,
)


def run_python_script(
    filename: str,
) -> None:

    path = BASE_DIR / "src" / filename

    subprocess.run(
        [
            sys.executable,
            str(path),
        ],
        check=True,
    )


def execute_sql_file(
    filename: str,
) -> None:

    path = SQL_DIR / filename

    sql_text = path.read_text(
        encoding="utf-8"
    )

    statements = sqlparse.split(
        sql_text
    )

    with engine.begin() as connection:
        for statement in statements:
            statement = statement.strip()

            if not statement:
                continue

            connection.execute(
                text(statement)
            )


def main():
    print(
        "\n1. Generating synthetic data..."
    )

    run_python_script(
        "generate_sample_data.py"
    )

    print(
        "\n2. Loading Bronze layer..."
    )

    run_python_script(
        "load_to_postgres.py"
    )

    print(
        "\n3. Creating Silver layer..."
    )

    execute_sql_file(
        "02_silver_views.sql"
    )

    print(
        "\n4. Creating Gold layer..."
    )

    execute_sql_file(
        "03_gold_views.sql"
    )

    print(
        "\nPipeline completed successfully."
    )

    print(
        "\nRun sql/04_validation.sql "
        "to inspect validation results."
    )


if __name__ == "__main__":
    main()
