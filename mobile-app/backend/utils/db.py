import os
import psycopg2
from dotenv import load_dotenv

load_dotenv()


def get_conn():
    """Return a new psycopg2 connection using DATABASE_URL or individual env vars."""
    database_url = os.getenv("DATABASE_URL")
    if database_url:
        return psycopg2.connect(database_url)

    host = os.getenv("DB_HOST", "localhost")
    port = os.getenv("DB_PORT", "5432")
    dbname = os.getenv("DB_NAME")
    user = os.getenv("DB_USER")
    password = os.getenv("DB_PASSWORD")

    if not dbname or not user or not password:
        raise EnvironmentError("Database configuration missing: set DATABASE_URL or DB_NAME/DB_USER/DB_PASSWORD")

    return psycopg2.connect(host=host, port=port, dbname=dbname, user=user, password=password)
