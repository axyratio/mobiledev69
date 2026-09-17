from rest_framework.authentication import SessionAuthentication


class CsrfExemptSessionAuthentication(SessionAuthentication):
    """Session auth without CSRF enforcement.

    The Flutter client is a native app authenticated by session cookie, not
    a browser page — it has no CSRF token to send, and DRF's
    `SessionAuthentication` enforces CSRF on its own regardless of a plain
    `@csrf_exempt` on the view. Use this wherever a session-authenticated
    endpoint accepts POST/PUT/PATCH/DELETE from that client.
    """

    def enforce_csrf(self, request):
        return
