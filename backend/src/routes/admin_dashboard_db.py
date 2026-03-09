import os
import psycopg2
from psycopg2.extras import RealDictCursor
from dotenv import load_dotenv

load_dotenv()
def get_main_db():
    return psycopg2.connect(
        host=os.getenv("DB_HOST"),
        database=os.getenv("DB_NAME"),
        user=os.getenv("DB_USER"),
        password=os.getenv("DB_PASSWORD"),
        port=os.getenv("DB_PORT"),
        cursor_factory=RealDictCursor
    )

def get_auth_db():
    try:
        return psycopg2.connect(
            host=os.getenv("AUTH_DB_HOST"),
            database=os.getenv("AUTH_DB_NAME"),
            user=os.getenv("AUTH_DB_USER"),
            password=os.getenv("AUTH_DB_PASSWORD"),
            port=os.getenv("AUTH_DB_PORT"),
            cursor_factory=RealDictCursor
        )
    except Exception as e:
        print("Auth DB connection error:", e)
        raise
