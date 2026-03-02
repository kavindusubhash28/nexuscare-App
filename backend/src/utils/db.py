import os
import psycopg2
from dotenv import load_dotenv

load_dotenv(override=True)


def get_conn():
    return psycopg2.connect(
        host=os.getenv("DB_HOST"),
        port=int(os.getenv("DB_PORT")),
        dbname=os.getenv("DB_NAME"),
        user=os.getenv("DB_USER"),
        password=os.getenv("DB_PASSWORD"),
        sslmode="require",  # IMPORTANT for Supabase
        
    )