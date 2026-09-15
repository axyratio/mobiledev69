from django.contrib import admin
from django.urls import include, path

from apps.accounts.views import current_user_view, login_view, register_view

urlpatterns = [
    path("admin/", admin.site.urls),
    # OIDC login/logout endpoints, e.g. /accounts/google/login/ and /accounts/logout/
    path("accounts/", include("allauth.urls")),
    path("api/auth/me/", current_user_view, name="current-user"),
    path("api/auth/register/", register_view, name="register"),
    path("api/auth/login/", login_view, name="login"),
]
