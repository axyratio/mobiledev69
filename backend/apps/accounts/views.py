from django.http import JsonResponse


def current_user_view(request):
    """Reports the current session's auth state (FR-01/FR-03).

    The Flutter client calls this on startup and after the OIDC redirect to
    decide whether to show the login screen or the authenticated app shell.
    """
    if not request.user.is_authenticated:
        return JsonResponse({"is_authenticated": False}, status=401)

    user = request.user
    return JsonResponse(
        {
            "is_authenticated": True,
            "id": user.id,
            "email": user.email,
            "name": user.get_full_name() or user.username,
            "theme_preference": user.theme_preference,
        }
    )
