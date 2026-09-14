from allauth.socialaccount.adapter import DefaultSocialAccountAdapter


class CustomSocialAccountAdapter(DefaultSocialAccountAdapter):
    """Binds the OIDC provider/sub onto the local User record (FR-01).

    django-allauth already creates and links the User <-> SocialAccount pair;
    this adapter additionally denormalizes provider + sub onto User itself so
    the fields required by the data model (Section 5) stay populated without
    an extra join for every request.
    """

    def populate_user(self, request, sociallogin, data):
        user = super().populate_user(request, sociallogin, data)
        user.oidc_provider = sociallogin.account.provider
        user.oidc_sub = sociallogin.account.uid
        return user

    def save_user(self, request, sociallogin, form=None):
        user = super().save_user(request, sociallogin, form)
        user.oidc_provider = sociallogin.account.provider
        user.oidc_sub = sociallogin.account.uid
        user.save(update_fields=["oidc_provider", "oidc_sub"])
        return user
