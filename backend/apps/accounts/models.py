from django.contrib.auth.models import AbstractUser
from django.db import models


class User(AbstractUser):
    """Application user, identified primarily via an OIDC provider (FR-01).

    `oidc_provider` + `oidc_sub` together identify the external identity that
    this account is bound to (e.g. provider="google", sub="1098237...").
    `theme_preference` backs the Dark Mode extra feature (FR-18).
    """

    class ThemePreference(models.TextChoices):
        LIGHT = "light", "Light"
        DARK = "dark", "Dark"

    oidc_provider = models.CharField(max_length=50, blank=True, default="")
    oidc_sub = models.CharField(max_length=255, blank=True, default="")
    theme_preference = models.CharField(
        max_length=10,
        choices=ThemePreference.choices,
        default=ThemePreference.LIGHT,
    )

    class Meta:
        constraints = [
            models.UniqueConstraint(
                fields=["oidc_provider", "oidc_sub"],
                name="unique_oidc_identity",
                condition=~models.Q(oidc_sub=""),
            )
        ]

    def __str__(self) -> str:
        return self.email or self.username
