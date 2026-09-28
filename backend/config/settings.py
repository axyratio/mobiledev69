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
    # OIDC: this backend is itself the OpenID Connect Provider (see /openid/)
    "oidc_provider",
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
    # Resolves request.user from an OIDC Bearer access token when no
    # session cookie authenticated the request (the Flutter client's path).
    "apps.accounts.middleware.OIDCBearerAuthenticationMiddleware",
    "django.contrib.messages.middleware.MessageMiddleware",
    "django.middleware.clickjacking.XFrameOptionsMiddleware",
]

ROOT_URLCONF = "config.urls"

TEMPLATES = [
    {
        "BACKEND": "django.template.backends.django.DjangoTemplates",
        # DIRS is searched before any app's own templates/ (APP_DIRS below),
        # so a template here overrides oidc_provider's own — e.g.
        # templates/oidc_provider/authorize.html replaces the package's
        # default consent page. Needed since oidc_provider precedes
        # apps.accounts in INSTALLED_APPS, so an app-level override alone
        # wouldn't win.
        "DIRS": [BASE_DIR / "templates"],
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
AUTHENTICATION_BACKENDS = [
    "django.contrib.auth.backends.ModelBackend",
]

# This backend is itself the OpenID Connect Provider the Flutter client
# authenticates against (Authorization Code + PKCE flow via /openid/),
# instead of verifying a third-party Google ID token. LOGIN_URL is Django's
# default ("/accounts/login/", wired up in config/urls.py via
# django.contrib.auth.urls) — django-oidc-provider's /openid/authorize/
# redirects there when the browser has no session yet, same as the old
# allauth redirect flow did.
#
# For web, landing on the raw /api/auth/me/ JSON after login/logout would
# leave that JSON on screen instead of the app, so both send the browser
# back to the frontend itself. The mobile app doesn't use this redirect
# flow's post-login page at all — it captures the `code` from the redirect
# URI before the browser ever gets here.
LOGIN_REDIRECT_URL = env.FRONTEND_URL
LOGOUT_REDIRECT_URL = env.FRONTEND_URL

# See apps/accounts/oidc.py — populates standard + app-specific (theme,
# CEFR level) claims for id_token and /openid/userinfo/ alike.
OIDC_USERINFO = "apps.accounts.oidc.userinfo"
OIDC_EXTRA_SCOPE_CLAIMS = "apps.accounts.oidc.AppScopeClaims"
OIDC_IDTOKEN_INCLUDE_CLAIMS = True

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
