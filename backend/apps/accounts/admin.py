from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as DjangoUserAdmin

from apps.accounts.models import User


@admin.register(User)
class UserAdmin(DjangoUserAdmin):
    list_display = (
        "username",
        "email",
        "oidc_provider",
        "theme_preference",
        "cefr_level",
        "cefr_level_filter_enabled",
        "highlight_filter_by_level_enabled",
        "is_staff",
    )
    list_filter = ("oidc_provider", "theme_preference", "cefr_level", "is_staff")
    fieldsets = DjangoUserAdmin.fieldsets + (
        (
            "OIDC & preferences",
            {
                "fields": (
                    "oidc_provider",
                    "oidc_sub",
                    "theme_preference",
                    "cefr_level",
                    "cefr_level_filter_enabled",
                    "highlight_filter_by_level_enabled",
                )
            },
        ),
    )
