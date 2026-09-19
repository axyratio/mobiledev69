import json

from django.conf import settings
from django.contrib.auth import authenticate, get_user_model
from django.contrib.auth import login as auth_login
from django.contrib.auth.password_validation import validate_password
from django.core.exceptions import ValidationError
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.views.decorators.http import require_POST
from google.auth.transport import requests as google_auth_requests
from google.oauth2 import id_token as google_id_token

User = get_user_model()

# A fresh Request per call would work too, but this reuses one urllib3
# connection pool across verifications instead of opening a new one every
# time (verify_oauth2_token uses it to fetch Google's public signing keys).
_google_auth_request = google_auth_requests.Request()


def _user_payload(user):
    return {
        "id": user.id,
        "email": user.email,
        "name": user.get_full_name() or user.username,
        "theme_preference": user.theme_preference,
        "cefr_level": user.cefr_level,
        "cefr_level_filter_enabled": user.cefr_level_filter_enabled,
        "highlight_filter_by_level_enabled": user.highlight_filter_by_level_enabled,
        "oidc_provider": user.oidc_provider,
    }


@csrf_exempt
@require_POST
def register_view(request):
    """Creates a new account with email + password (FR-01 email/password path).

    Exempt from CSRF like the OIDC endpoints: the Flutter client is a native
    app, not a browser, so it has no CSRF cookie/token to send.
    """
    try:
        data = json.loads(request.body or "{}")
    except json.JSONDecodeError:
        return JsonResponse({"detail": "Invalid JSON body."}, status=400)

    first_name = (data.get("first_name") or "").strip()
    last_name = (data.get("last_name") or "").strip()
    email = (data.get("email") or "").strip().lower()
    password = data.get("password") or ""

    if not first_name or not email or not password:
        return JsonResponse(
            {"detail": "First name, email and password are required."}, status=400
        )
    if User.objects.filter(email__iexact=email).exists():
        return JsonResponse({"detail": "An account with this email already exists."}, status=400)

    try:
        validate_password(password)
    except ValidationError as exc:
        return JsonResponse({"detail": " ".join(exc.messages)}, status=400)

    user = User(username=email, email=email, first_name=first_name, last_name=last_name)
    user.set_password(password)
    user.save()

    # Multiple AUTHENTICATION_BACKENDS are configured (ModelBackend +
    # allauth's), so login() needs to be told which one to trust since this
    # user wasn't produced by authenticate().
    user.backend = "django.contrib.auth.backends.ModelBackend"
    auth_login(request, user)
    return JsonResponse(_user_payload(user), status=201)


@csrf_exempt
@require_POST
def login_view(request):
    """Authenticates via email + password and establishes a session cookie."""
    try:
        data = json.loads(request.body or "{}")
    except json.JSONDecodeError:
        return JsonResponse({"detail": "Invalid JSON body."}, status=400)

    email = (data.get("email") or "").strip().lower()
    password = data.get("password") or ""

    try:
        user_obj = User.objects.get(email__iexact=email)
    except User.DoesNotExist:
        return JsonResponse({"detail": "Invalid email or password."}, status=401)

    user = authenticate(request, username=user_obj.username, password=password)
    if user is None:
        return JsonResponse({"detail": "Invalid email or password."}, status=401)

    auth_login(request, user)
    return JsonResponse(_user_payload(user))


@csrf_exempt
@require_POST
def google_token_login_view(request):
    """Verifies a Google ID token from the native Sign-In SDK and
    establishes a session (FR-01).

    Used by the mobile app instead of the browser-redirect OIDC flow:
    `google_sign_in` on the device handles the account picker natively
    (Google Play Services / native iOS SDK), sharing whatever Google
    account is already signed in there, and hands back an ID token whose
    audience is this same `GOOGLE_OIDC_CLIENT_ID` (the app passes it as
    `serverClientId`) — so it verifies with the same web client allauth
    already uses, no separate mobile secret needed on this side.
    """
    try:
        data = json.loads(request.body or "{}")
    except json.JSONDecodeError:
        return JsonResponse({"detail": "Invalid JSON body."}, status=400)

    token = data.get("id_token") or ""
    try:
        payload = google_id_token.verify_oauth2_token(
            token, _google_auth_request, audience=settings.GOOGLE_OIDC_CLIENT_ID
        )
    except ValueError:
        return JsonResponse({"detail": "Invalid Google ID token."}, status=400)

    sub = payload.get("sub") or ""
    email = (payload.get("email") or "").strip().lower()
    if not sub or not email:
        return JsonResponse({"detail": "Google account has no usable email."}, status=400)

    try:
        user = User.objects.get(oidc_provider="google", oidc_sub=sub)
    except User.DoesNotExist:
        # Fall back to an existing email/password (or web-OIDC) account so
        # the same person doesn't end up with two disconnected users.
        user = User.objects.filter(email__iexact=email).first()
        if user is None:
            user = User(username=email, email=email)
            user.set_unusable_password()
        user.oidc_provider = "google"
        user.oidc_sub = sub
        user.first_name = user.first_name or payload.get("given_name") or ""
        user.last_name = user.last_name or payload.get("family_name") or ""
        user.save()

    user.backend = "django.contrib.auth.backends.ModelBackend"
    auth_login(request, user)
    return JsonResponse(_user_payload(user))


@csrf_exempt
@require_POST
def update_theme_preference_view(request):
    """Persists the learner's chosen theme (FR-17/FR-18 Dark Mode), so it's
    remembered on every future visit instead of resetting each session.
    """
    if not request.user.is_authenticated:
        return JsonResponse({"detail": "Authentication required."}, status=401)

    try:
        data = json.loads(request.body or "{}")
    except json.JSONDecodeError:
        return JsonResponse({"detail": "Invalid JSON body."}, status=400)

    theme = data.get("theme_preference")
    if theme not in User.ThemePreference.values:
        return JsonResponse(
            {"detail": f"theme_preference must be one of {', '.join(User.ThemePreference.values)}."},
            status=400,
        )

    request.user.theme_preference = theme
    request.user.save(update_fields=["theme_preference"])
    return JsonResponse(_user_payload(request.user))


@csrf_exempt
@require_POST
def update_cefr_level_view(request):
    """Persists the learner's chosen CEFR level (highlight filter on Story
    Detail), so it's remembered on every future visit instead of resetting
    to A1 each time.
    """
    if not request.user.is_authenticated:
        return JsonResponse({"detail": "Authentication required."}, status=401)

    try:
        data = json.loads(request.body or "{}")
    except json.JSONDecodeError:
        return JsonResponse({"detail": "Invalid JSON body."}, status=400)

    level = data.get("cefr_level")
    if level not in User.CefrLevel.values:
        return JsonResponse(
            {"detail": f"cefr_level must be one of {', '.join(User.CefrLevel.values)}."},
            status=400,
        )

    request.user.cefr_level = level
    request.user.save(update_fields=["cefr_level"])
    return JsonResponse(_user_payload(request.user))


@csrf_exempt
@require_POST
def update_cefr_level_filter_view(request):
    """Persists whether the create-story word randomizer should be limited
    to the learner's own CEFR level and below (Settings toggle).
    """
    if not request.user.is_authenticated:
        return JsonResponse({"detail": "Authentication required."}, status=401)

    try:
        data = json.loads(request.body or "{}")
    except json.JSONDecodeError:
        return JsonResponse({"detail": "Invalid JSON body."}, status=400)

    enabled = data.get("cefr_level_filter_enabled")
    if not isinstance(enabled, bool):
        return JsonResponse(
            {"detail": "cefr_level_filter_enabled must be a boolean."}, status=400
        )

    request.user.cefr_level_filter_enabled = enabled
    request.user.save(update_fields=["cefr_level_filter_enabled"])
    return JsonResponse(_user_payload(request.user))


@csrf_exempt
@require_POST
def update_highlight_level_filter_view(request):
    """Persists whether Story Detail highlighting should be limited to the
    learner's own CEFR level and above (Settings toggle).
    """
    if not request.user.is_authenticated:
        return JsonResponse({"detail": "Authentication required."}, status=401)

    try:
        data = json.loads(request.body or "{}")
    except json.JSONDecodeError:
        return JsonResponse({"detail": "Invalid JSON body."}, status=400)

    enabled = data.get("highlight_filter_by_level_enabled")
    if not isinstance(enabled, bool):
        return JsonResponse(
            {"detail": "highlight_filter_by_level_enabled must be a boolean."}, status=400
        )

    request.user.highlight_filter_by_level_enabled = enabled
    request.user.save(update_fields=["highlight_filter_by_level_enabled"])
    return JsonResponse(_user_payload(request.user))


def current_user_view(request):
    """Reports the current session's auth state (FR-01/FR-03).

    The Flutter client calls this on startup and after the OIDC redirect to
    decide whether to show the login screen or the authenticated app shell.
    """
    if not request.user.is_authenticated:
        return JsonResponse({"is_authenticated": False}, status=401)

    return JsonResponse({"is_authenticated": True, **_user_payload(request.user)})
