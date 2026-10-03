from django.contrib import admin
from django.urls import include, path

from apps.accounts.views import (
    current_user_view,
    logout_view,
    oidc_signup_view,
    update_cefr_level_filter_view,
    update_cefr_level_view,
    update_highlight_level_filter_view,
    update_theme_preference_view,
)

urlpatterns = [
    path("admin/", admin.site.urls),
    # Django's own login/logout/password pages, e.g. /accounts/login/ — this
    # is where django-oidc-provider's /openid/authorize/ redirects a browser
    # that has no session yet (see LOGIN_URL), same role the old allauth
    # redirect flow played. oidc_signup_view fills the one gap it doesn't
    # cover: creating a brand new account from that same browser page.
    path("accounts/logout/", logout_view, name="logout"),
    path("accounts/", include("django.contrib.auth.urls")),
    path("accounts/signup/", oidc_signup_view, name="oidc-signup"),
    # This backend's own OpenID Connect Provider endpoints (FR-01/FR-02),
    # e.g. /openid/authorize/, /openid/token/, /openid/userinfo/,
    # /openid/.well-known/openid-configuration/ — replaces the previous
    # allauth + Google OIDC integration. The Flutter client authenticates
    # against these via the standard Authorization Code + PKCE flow.
    path("openid/", include("oidc_provider.urls", namespace="oidc_provider")),
    path("api/auth/me/", current_user_view, name="current-user"),
    path("api/auth/theme/", update_theme_preference_view, name="update-theme-preference"),
    path("api/auth/cefr-level/", update_cefr_level_view, name="update-cefr-level"),
    path(
        "api/auth/cefr-level-filter/",
        update_cefr_level_filter_view,
        name="update-cefr-level-filter",
    ),
    path(
        "api/auth/highlight-level-filter/",
        update_highlight_level_filter_view,
        name="update-highlight-level-filter",
    ),
    path("api/", include("apps.stories.urls")),
]
