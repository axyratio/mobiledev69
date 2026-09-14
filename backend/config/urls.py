from django.contrib import admin
from django.urls import include, path

from apps.accounts.views import current_user_view

urlpatterns = [
    path("admin/", admin.site.urls),
    # OIDC login/logout endpoints, e.g. /accounts/google/login/ and /accounts/logout/
    path("accounts/", include("allauth.urls")),
    path("api/auth/me/", current_user_view, name="current-user"),
]
