"""Central configuration module.

All environment-variable access for the project must go through this module.
Business logic and settings.py should never call `os.environ` directly.
"""
import os
from pathlib import Path

from dotenv import load_dotenv

BASE_DIR = Path(__file__).resolve().parent.parent
load_dotenv(BASE_DIR / ".env")


def _read_bool(key: str, default: bool) -> bool:
    """Parses a boolean-like environment variable, falling back to a default."""
    raw_value = os.environ.get(key)
    if raw_value is None:
        return default
    return raw_value.strip().lower() in {"1", "true", "yes", "on"}


def _read_list(key: str, default: str) -> list[str]:
    """Parses a comma-separated environment variable into a list of strings."""
    raw_value = os.environ.get(key, default)
    return [item.strip() for item in raw_value.split(",") if item.strip()]


class Env:
    """Typed accessor for application environment variables (fail-soft with dev defaults)."""

    SECRET_KEY: str = os.environ.get("DJANGO_SECRET_KEY", "insecure-dev-key-change-me")
    DEBUG: bool = _read_bool("DJANGO_DEBUG", True)
    ALLOWED_HOSTS: list[str] = _read_list("DJANGO_ALLOWED_HOSTS", "localhost,127.0.0.1")

    DATABASE_URL: str = os.environ.get("DATABASE_URL", f"sqlite:///{BASE_DIR / 'db.sqlite3'}")

    GOOGLE_OIDC_CLIENT_ID: str = os.environ.get("GOOGLE_OIDC_CLIENT_ID", "")
    GOOGLE_OIDC_CLIENT_SECRET: str = os.environ.get("GOOGLE_OIDC_CLIENT_SECRET", "")

    FRONTEND_URL: str = os.environ.get("FRONTEND_URL", "http://localhost:8080")
    CORS_ALLOWED_ORIGINS: list[str] = _read_list(
        "CORS_ALLOWED_ORIGINS", "http://localhost:8080"
    )

    LLM_API_KEY: str = os.environ.get("LLM_API_KEY", "")


env = Env()
