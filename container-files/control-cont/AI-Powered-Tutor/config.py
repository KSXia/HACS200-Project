import os

from dotenv import load_dotenv

load_dotenv()


class Config:
    SECRET_KEY = os.environ.get("SECRET_KEY", "dev")
    DATABASE_URL = os.environ.get("DATABASE_URL", "postgres://localhost/tutor")
    LLM_API_KEY = os.environ.get("LLM_API_KEY", "")
    LLM_API_URL = os.environ.get("LLM_API_URL", "https://api.example.com/v1/complete")
    STRIPE_API_KEY = os.environ.get("STRIPE_API_KEY", "")
    MAX_QUESTION_LENGTH = 2000
    RATE_LIMIT_PER_MINUTE = 30


class TestConfig(Config):
    TESTING = True
    DATABASE_URL = "postgres://localhost/tutor_test"
