import psycopg2
from flask import current_app, g


def get_db():
    if "db" not in g:
        g.db = psycopg2.connect(current_app.config["DATABASE_URL"])
    return g.db


def close_db(exc=None):
    db = g.pop("db", None)
    if db is not None:
        db.close()


def init_app(app):
    app.teardown_appcontext(close_db)


def log_question(user_id, question, answer):
    conn = get_db()
    with conn, conn.cursor() as cur:
        cur.execute(
            "INSERT INTO questions (user_id, question, answer) VALUES (%s, %s, %s)",
            (user_id, question, answer),
        )
