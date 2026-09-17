import json

from django.contrib.auth import authenticate, get_user_model
from django.contrib.auth import login as auth_login
from django.contrib.auth.password_validation import validate_password
from django.core.exceptions import ValidationError
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.views.decorators.http import require_POST

User = get_user_model()


def _user_payload(user):
    return {
        "id": user.id,
        "email": user.email,
        "name": user.get_full_name() or user.username,
        "theme_preference": user.theme_preference,
        "cefr_level": user.cefr_level,
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


def current_user_view(request):
    """Reports the current session's auth state (FR-01/FR-03).

    The Flutter client calls this on startup and after the OIDC redirect to
    decide whether to show the login screen or the authenticated app shell.
    """
    if not request.user.is_authenticated:
        return JsonResponse({"is_authenticated": False}, status=401)

    return JsonResponse({"is_authenticated": True, **_user_payload(request.user)})
