from django.contrib.auth.models import AbstractUser
from django.db import models


class User(AbstractUser):
    """Application user, identified primarily via an OIDC provider (FR-01).

    `oidc_provider` + `oidc_sub` together identify the external identity that
    this account is bound to (e.g. provider="google", sub="1098237...").
    `theme_preference` backs the Dark Mode extra feature (FR-18).
    `cefr_level` is the learner's own level: on the Story Detail screen, only
    target words at or above it get highlighted (words below it are treated
    as already known).
    """

    class ThemePreference(models.TextChoices):
        LIGHT = "light", "Light"
        DARK = "dark", "Dark"

    class CefrLevel(models.TextChoices):
        A1 = "A1", "A1"
        A2 = "A2", "A2"
        B1 = "B1", "B1"
        B2 = "B2", "B2"

    oidc_provider = models.CharField(max_length=50, blank=True, default="")
    oidc_sub = models.CharField(max_length=255, blank=True, default="")
    theme_preference = models.CharField(
        max_length=10,
        choices=ThemePreference.choices,
        default=ThemePreference.LIGHT,
    )
    cefr_level = models.CharField(
        max_length=2,
        choices=CefrLevel.choices,
        default=CefrLevel.A1,
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
