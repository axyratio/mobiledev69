"""Django settings for the Read English Story backend."""
import dj_database_url

from config.env import BASE_DIR, env

SECRET_KEY = env.SECRET_KEY
DEBUG = env.DEBUG
ALLOWED_HOSTS = env.ALLOWED_HOSTS

INSTALLED_APPS = [
    "django.contrib.admin",
    "django.contrib.auth",
    "django.contrib.contenttypes",
    "django.contrib.sessions",
    "django.contrib.messages",
    "django.contrib.staticfiles",
    "django.contrib.sites",
    # OIDC / social login
    "allauth",
    "allauth.account",
    "allauth.socialaccount",
    "allauth.socialaccount.providers.google",
    # API
    "rest_framework",
    "corsheaders",
    # Local apps
    "apps.accounts",
    "apps.stories",
]

MIDDLEWARE = [
    "django.middleware.security.SecurityMiddleware",
    "corsheaders.middleware.CorsMiddleware",
    "django.contrib.sessions.middleware.SessionMiddleware",
    "django.middleware.common.CommonMiddleware",
    "django.middleware.csrf.CsrfViewMiddleware",
    "django.contrib.auth.middleware.AuthenticationMiddleware",
    "django.contrib.messages.middleware.MessageMiddleware",
    "django.middleware.clickjacking.XFrameOptionsMiddleware",
    "allauth.account.middleware.AccountMiddleware",
]

ROOT_URLCONF = "config.urls"

TEMPLATES = [
    {
        "BACKEND": "django.template.backends.django.DjangoTemplates",
        "DIRS": [],
        "APP_DIRS": True,
        "OPTIONS": {
            "context_processors": [
                "django.template.context_processors.debug",
                "django.template.context_processors.request",
                "django.contrib.auth.context_processors.auth",
                "django.contrib.messages.context_processors.messages",
            ],
        },
    },
]

WSGI_APPLICATION = "config.wsgi.application"
ASGI_APPLICATION = "config.asgi.application"

DATABASES = {
    "default": dj_database_url.parse(env.DATABASE_URL, conn_max_age=600)
}

AUTH_USER_MODEL = "accounts.User"

AUTH_PASSWORD_VALIDATORS = [
    {"NAME": "django.contrib.auth.password_validation.UserAttributeSimilarityValidator"},
    {"NAME": "django.contrib.auth.password_validation.MinimumLengthValidator"},
    {"NAME": "django.contrib.auth.password_validation.CommonPasswordValidator"},
    {"NAME": "django.contrib.auth.password_validation.NumericPasswordValidator"},
]

LANGUAGE_CODE = "en-us"
TIME_ZONE = "Asia/Bangkok"
USE_I18N = True
USE_TZ = True

STATIC_URL = "static/"
DEFAULT_AUTO_FIELD = "django.db.models.BigAutoField"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Auth / OIDC (FR-01, FR-02, FR-03)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SITE_ID = 1

AUTHENTICATION_BACKENDS = [
    "django.contrib.auth.backends.ModelBackend",
    "allauth.account.auth_backends.AuthenticationBackend",
]

SOCIALACCOUNT_ADAPTER = "apps.accounts.adapters.CustomSocialAccountAdapter"

# Also read directly (not just via SOCIALACCOUNT_PROVIDERS below) so
# apps/accounts/views.py can verify a Google ID token from the mobile app's
# native Sign-In SDK against the same web client — see
# google_token_login_view.
GOOGLE_OIDC_CLIENT_ID = env.GOOGLE_OIDC_CLIENT_ID

SOCIALACCOUNT_PROVIDERS = {
    "google": {
        "APP": {
            "client_id": GOOGLE_OIDC_CLIENT_ID,
            "secret": env.GOOGLE_OIDC_CLIENT_SECRET,
            "key": "",
        },
        "SCOPE": ["openid", "profile", "email"],
        "AUTH_PARAMS": {"access_type": "online", "prompt": "select_account"},
        "OAUTH_PKCE_ENABLED": True,
    }
}

# Login/logout complete the OIDC redirect in a single GET (no intermediate confirm
# page). LOGIN_REDIRECT_URL only matters for a real browser tab (Flutter web, FR-01)
# — the mobile app doesn't use this redirect flow at all (see
# google_token_login_view). For web, landing on the raw /api/auth/me/ JSON would
# leave that JSON on screen instead of the app, so both login and logout send the
# browser back to the frontend itself.
SOCIALACCOUNT_LOGIN_ON_GET = True
ACCOUNT_LOGOUT_ON_GET = True

LOGIN_REDIRECT_URL = env.FRONTEND_URL
ACCOUNT_LOGOUT_REDIRECT_URL = env.FRONTEND_URL

# Session-only auth is sufficient for Day 1; session expires -> FR-03 redirect-to-login
# is enforced client-side by checking /api/auth/me/.
SESSION_COOKIE_AGE = 60 * 60 * 24 * 7  # 7 days
SESSION_EXPIRE_AT_BROWSER_CLOSE = False

# The Flutter web build lives on a different origin than this backend
# (e.g. read-english-story-web.onrender.com vs mobiledev69.onrender.com),
# so the session cookie is cross-site from the browser's point of view.
# SameSite=None + Secure is required for a cross-site cookie to be sent at
# all; kept as Lax/insecure under DEBUG since local dev runs over plain
# http, where SameSite=None cookies are rejected outright.
SESSION_COOKIE_SECURE = not DEBUG
SESSION_COOKIE_SAMESITE = "None" if not DEBUG else "Lax"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# CORS (Flutter web / mobile client)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
CORS_ALLOWED_ORIGINS = env.CORS_ALLOWED_ORIGINS
CORS_ALLOW_CREDENTIALS = True

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# DRF
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
REST_FRAMEWORK = {
    "DEFAULT_AUTHENTICATION_CLASSES": [
        "rest_framework.authentication.SessionAuthentication",
    ],
    "DEFAULT_PERMISSION_CLASSES": [
        "rest_framework.permissions.IsAuthenticated",
    ],
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Logging (NFR-05: log failures for debugging)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
LOGGING = {
    "version": 1,
    "disable_existing_loggers": False,
    "formatters": {
        "structured": {
            "format": '{"level": "%(levelname)s", "logger": "%(name)s", '
            '"message": "%(message)s", "time": "%(asctime)s"}'
        },
    },
    "handlers": {
        "console": {"class": "logging.StreamHandler", "formatter": "structured"},
    },
    "root": {"handlers": ["console"], "level": "INFO"},
    "loggers": {
        "django.request": {"handlers": ["console"], "level": "ERROR", "propagate": False},
    },
}
