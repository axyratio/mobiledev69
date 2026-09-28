from oidc_provider.lib.claims import ScopeClaims


def userinfo(claims, user):
    """Populates OIDC standard claims from the local User record (FR-01).

    Wired up via OIDC_USERINFO; feeds both id_token (OIDC_IDTOKEN_INCLUDE_CLAIMS)
    and /openid/userinfo/ for the "profile"/"email" scopes.
    """
    claims["name"] = user.get_full_name() or user.username
    claims["given_name"] = user.first_name
    claims["family_name"] = user.last_name
    claims["preferred_username"] = user.username
    claims["email"] = user.email
    claims["email_verified"] = bool(user.email)
    return claims


class AppScopeClaims(ScopeClaims):
    """Extra "app_profile" scope carrying this app's own preferences
    (FR-17/FR-18 Dark Mode, CEFR level), so a client gets them alongside the
    standard profile/email claims in the same id_token / userinfo response
    instead of a separate /api/auth/me/ round trip.
    """

    info_app_profile = (
        "App preferences",
        "Access to your Read English Story preferences (theme, CEFR level).",
    )

    def scope_app_profile(self):
        user = self.user
        return {
            "oidc_provider": user.oidc_provider,
            "theme_preference": user.theme_preference,
            "cefr_level": user.cefr_level,
            "cefr_level_filter_enabled": user.cefr_level_filter_enabled,
            "highlight_filter_by_level_enabled": user.highlight_filter_by_level_enabled,
        }
