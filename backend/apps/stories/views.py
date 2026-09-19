import logging
import random
from datetime import datetime
from zoneinfo import ZoneInfo

from django.shortcuts import get_object_or_404
from rest_framework import generics, status
from rest_framework.decorators import api_view, authentication_classes, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response

from apps.accounts.authentication import CsrfExemptSessionAuthentication

from .llm import (
    MAX_PARAGRAPHS,
    MAX_WORDS,
    MIN_PARAGRAPHS,
    MIN_WORDS,
    LLMGenerationError,
    generate_story,
)
from .models import Story, StoryWord, Word
from .serializers import StoryDetailSerializer, StorySerializer

logger = logging.getLogger(__name__)

TODAY_WORD_COUNT = 4
BANGKOK = ZoneInfo("Asia/Bangkok")

# Same ordering used by serializers._CEFR_ORDER — CEFR levels are easiest to
# hardest, so "words at or below my level" is a prefix of this list.
_CEFR_ORDER = [choice.value for choice in Word.CefrLevel]

# Fixed chip options shown on the create form (mockup 1e) — allowlisted
# rather than free text so the optional genre can never carry a prompt
# injection payload (NFR-03).
ALLOWED_GENRES = {"ลึกลับ", "อบอุ่น", "ตลก", "ไซไฟ"}
MAX_GENRE_LENGTH = 40

MAX_SEARCH_RESULTS = 20

# Matches the mockup's rename field (FR-10) — shorter than the model's
# storage limit (200) since it's a UX cap on editing, not on generation.
MAX_TITLE_LENGTH = 80


class StoryListView(generics.ListAPIView):
    """My Stories feed for Home (FR-08 groundwork).

    Scoped to `request.user` regardless of what the client asks for
    (NFR-02) — there is no owner/user_id query param to spoof.
    """

    serializer_class = StorySerializer

    def get_queryset(self):
        return (
            Story.objects.filter(owner=self.request.user)
            .order_by("-created_at")
            .prefetch_related("words")
        )


@api_view(["GET"])
@permission_classes([AllowAny])
def words_today_view(request):
    """A small daily sample of vocabulary words, visible even to guests
    (permission matrix: Dark Mode/word preview work while logged out).

    Deterministic per calendar day in Asia/Bangkok so the sample is stable
    all day and only changes at midnight, matching the mockup's copy
    ("เปลี่ยนใหม่ทุกเที่ยงคืน").
    """
    today = datetime.now(BANGKOK).date().isoformat()
    word_ids = list(Word.objects.values_list("id", flat=True))
    sample_size = min(TODAY_WORD_COUNT, len(word_ids))
    sampled_ids = random.Random(today).sample(word_ids, sample_size) if sample_size else []
    words = Word.objects.filter(id__in=sampled_ids)
    by_id = {word.id: word.lemma for word in words}
    return Response({"words": [by_id[word_id] for word_id in sampled_ids]})


@api_view(["POST"])
@authentication_classes([CsrfExemptSessionAuthentication])
def random_words_view(request):
    """Samples random vocabulary words for the create-story flow (FR-05).

    Accepts an optional `exclude_ids` so the client can re-roll the whole
    set or a single word without repeating what's already shown. When the
    learner has turned on "randomize by my level" in Settings, the pool is
    narrowed to their `cefr_level` and above instead of the whole bank —
    words below it are treated as already known, same cutoff direction as
    the Story Detail highlighter.
    """
    try:
        count = int(request.data.get("count"))
    except (TypeError, ValueError):
        return Response({"detail": "count must be a number."}, status=status.HTTP_400_BAD_REQUEST)
    # Bounded by MAX_WORDS (a full story's word count), but 1 is allowed so a
    # single word can be re-rolled without pulling a whole new set.
    if not (1 <= count <= MAX_WORDS):
        return Response(
            {"detail": f"count must be between 1 and {MAX_WORDS}."},
            status=status.HTTP_400_BAD_REQUEST,
        )

    exclude_ids = request.data.get("exclude_ids") or []
    if not isinstance(exclude_ids, list):
        return Response({"detail": "exclude_ids must be a list."}, status=status.HTTP_400_BAD_REQUEST)

    word_pool = Word.objects.exclude(id__in=exclude_ids)
    if request.user.cefr_level_filter_enabled:
        allowed_levels = _CEFR_ORDER[_CEFR_ORDER.index(request.user.cefr_level) :]
        word_pool = word_pool.filter(cefr_level__in=allowed_levels)

    word_ids = list(word_pool.values_list("id", flat=True))
    if len(word_ids) < count:
        return Response({"detail": "Not enough words available."}, status=status.HTTP_400_BAD_REQUEST)

    sampled_ids = random.sample(word_ids, count)
    words = Word.objects.filter(id__in=sampled_ids)
    by_id = {word.id: word.lemma for word in words}
    return Response({"words": [{"id": word_id, "word": by_id[word_id]} for word_id in sampled_ids]})


@api_view(["GET"])
def words_search_view(request):
    """Searches the vocabulary bank so a user can hand-pick words instead of
    relying on the random sample (extends FR-05 with an opt-in manual pick).
    """
    query = (request.query_params.get("q") or "").strip()
    if not query:
        return Response({"words": []})

    matches = Word.objects.filter(lemma__icontains=query).order_by("lemma")[:MAX_SEARCH_RESULTS]
    return Response({"words": [{"id": word.id, "word": word.lemma} for word in matches]})


@api_view(["POST"])
@authentication_classes([CsrfExemptSessionAuthentication])
def generate_story_view(request):
    """Calls Gemini with the confirmed words and saves the result (FR-06, FR-07)."""
    word_ids = request.data.get("word_ids")
    if not isinstance(word_ids, list) or not (MIN_WORDS <= len(word_ids) <= MAX_WORDS):
        return Response(
            {"detail": f"word_ids must be a list of {MIN_WORDS}-{MAX_WORDS} ids."},
            status=status.HTTP_400_BAD_REQUEST,
        )

    try:
        paragraph_count = int(request.data.get("paragraph_count", 1))
    except (TypeError, ValueError):
        return Response({"detail": "paragraph_count must be a number."}, status=status.HTTP_400_BAD_REQUEST)
    if not (MIN_PARAGRAPHS <= paragraph_count <= MAX_PARAGRAPHS):
        return Response(
            {"detail": f"paragraph_count must be between {MIN_PARAGRAPHS} and {MAX_PARAGRAPHS}."},
            status=status.HTTP_400_BAD_REQUEST,
        )

    genre = str(request.data.get("genre") or "").strip()[:MAX_GENRE_LENGTH]
    if genre not in ALLOWED_GENRES:
        genre = ""

    words = list(Word.objects.filter(id__in=word_ids))
    if len(words) != len(set(word_ids)):
        return Response({"detail": "One or more words no longer exist."}, status=status.HTTP_400_BAD_REQUEST)

    try:
        result = generate_story(
            [word.lemma for word in words],
            genre=genre,
            paragraph_count=paragraph_count,
        )
    except LLMGenerationError as exc:
        logger.error("Story generation failed for user %s: %s", request.user.id, exc)
        return Response({"detail": str(exc)}, status=status.HTTP_502_BAD_GATEWAY)

    used_lower = {word.lower() for word in result["used_words"]}
    used_words = [word for word in words if word.lemma.lower() in used_lower] or words

    story = Story.objects.create(
        owner=request.user,
        title=result["title"],
        body=result["body"],
        prompt_used=result["prompt"],
    )
    StoryWord.objects.bulk_create([StoryWord(story=story, word=word) for word in used_words])

    return Response(StoryDetailSerializer(story).data, status=status.HTTP_201_CREATED)


@api_view(["GET", "PATCH", "DELETE"])
@authentication_classes([CsrfExemptSessionAuthentication])
def story_detail_view(request, pk):
    """Full story view for Detail (FR-09), rename (FR-10) and delete
    (FR-11), all scoped to the owner (NFR-02, FR-12).

    `on_delete=models.CASCADE` on `StoryWord` takes care of NFR-06 (no
    orphan word links) when the story itself is deleted.
    """
    story = get_object_or_404(Story.objects.prefetch_related("words"), pk=pk, owner=request.user)

    if request.method == "DELETE":
        story.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)

    if request.method == "PATCH":
        title = str(request.data.get("title", "")).strip()
        if not title:
            return Response({"detail": "กรุณาระบุชื่อเรื่อง"}, status=status.HTTP_400_BAD_REQUEST)
        if len(title) > MAX_TITLE_LENGTH:
            return Response(
                {"detail": f"ชื่อเรื่องต้องไม่เกิน {MAX_TITLE_LENGTH} ตัวอักษร"},
                status=status.HTTP_400_BAD_REQUEST,
            )
        story.title = title
        story.save(update_fields=["title", "updated_at"])

    return Response(StoryDetailSerializer(story).data)
