from oidc_provider.models import Token as OIDCToken


class OIDCBearerAuthenticationMiddleware:
    """Resolves `request.user` from an OIDC Bearer access token (FR-01).

    The Flutter client authenticates through this backend's own OIDC
    Authorization Code + PKCE flow (see /openid/) and gets back an access
    token instead of a session cookie, so it can't rely on
    AuthenticationMiddleware alone. Runs right after it and only kicks in
    when the session didn't already authenticate the request — every view
    that reads `request.user` (the plain JsonResponse views in
    apps.accounts.views and the DRF views in apps.stories.views, via
    SessionAuthentication reading request._request.user) then works the
    same way regardless of which auth path was used.
    """

    prefix = "Bearer "

    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        if not request.user.is_authenticated:
            token = self._authenticate(request)
            if token is not None:
                request.user = token.user
        return self.get_response(request)

    def _authenticate(self, request):
        auth = request.META.get("HTTP_AUTHORIZATION", "")
        if not auth.startswith(self.prefix):
            return None

        access_token = auth[len(self.prefix):].strip()
        if not access_token:
            return None

        try:
            token = OIDCToken.objects.select_related("user").get(access_token=access_token)
        except OIDCToken.DoesNotExist:
            return None

        if token.user is None or token.has_expired():
            return None

        return token
