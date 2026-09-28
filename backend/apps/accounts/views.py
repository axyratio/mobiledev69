import json

from django.conf import settings
from django.contrib.auth import get_user_model
from django.contrib.auth import login as auth_login
from django.contrib.auth.password_validation import validate_password
from django.core.exceptions import ValidationError
from django.http import JsonResponse
from django.shortcuts import redirect, render
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
        "cefr_level_filter_enabled": user.cefr_level_filter_enabled,
        "highlight_filter_by_level_enabled": user.highlight_filter_by_level_enabled,
        "oidc_provider": user.oidc_provider,
    }


def oidc_signup_view(request):
    """Browser-based sign-up page for the OIDC login flow (FR-01).

    This is now the *only* way to create an account — the Flutter client no
    longer has its own email/password form, since every login/signup goes
    through this backend's own OIDC provider (see /openid/). Django's own
    LoginView (see /accounts/login/) has no matching sign-up counterpart, so
    this fills that gap directly: most real IdP hosted-login pages (Auth0,
    Okta, even Google's own) offer account creation right alongside login
    for the same reason.
    """
    next_url = request.GET.get("next") or request.POST.get("next") or ""
    form_values = {"username": "", "first_name": "", "last_name": "", "email": ""}
    error = None

    if request.method == "POST":
        username = (request.POST.get("username") or "").strip()
        first_name = (request.POST.get("first_name") or "").strip()
        last_name = (request.POST.get("last_name") or "").strip()
        email = (request.POST.get("email") or "").strip().lower()
        password = request.POST.get("password") or ""
        form_values = {
            "username": username,
            "first_name": first_name,
            "last_name": last_name,
            "email": email,
        }

        if not username or not first_name or not email or not password:
            error = "Username, first name, email and password are required."
        elif User.objects.filter(username__iexact=username).exists():
            error = "That username is already taken."
        elif User.objects.filter(email__iexact=email).exists():
            error = "An account with this email already exists."
        else:
            try:
                validate_password(password)
            except ValidationError as exc:
                error = " ".join(exc.messages)

        if error is None:
            user = User(
                username=username, email=email, first_name=first_name, last_name=last_name
            )
            user.set_password(password)
            user.save()
            user.backend = "django.contrib.auth.backends.ModelBackend"
            auth_login(request, user)
            return redirect(next_url or settings.LOGIN_REDIRECT_URL)

    return render(
        request,
        "registration/signup.html",
        {"error": error, "next": next_url, "form_values": form_values},
    )


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
