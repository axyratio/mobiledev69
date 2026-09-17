import re

from rest_framework import serializers

from .models import Story, Word

SNIPPET_LENGTH = 140

# Extra/incidental vocabulary matches (words the LLM happened to use that
# weren't requested) only surface at this CEFR level or above — A1 words are
# common enough that flagging them as "bonus vocabulary" isn't useful.
_CEFR_ORDER = [choice.value for choice in Word.CefrLevel]
EXTRA_WORD_MIN_LEVEL = Word.CefrLevel.A2
_ALLOWED_EXTRA_LEVELS = _CEFR_ORDER[_CEFR_ORDER.index(EXTRA_WORD_MIN_LEVEL):]


def _word_payload(word: Word) -> dict:
    return {
        "word": word.lemma,
        "cefr_level": word.cefr_level,
        "definition_en": word.definition_en,
        "definition_th": word.definition_th,
        "example": word.example,
    }


def _incidental_words(body: str, exclude_lemmas: set[str]) -> list[Word]:
    """Vocabulary bank words (other than the ones the story was generated
    from) that also appear in [body], matched on a word boundary the same
    way `llm._used_words` matches requested words.

    Restricted to A2+ so every A1 word in the bank isn't flagged as a
    "bonus" highlight.
    """
    body_lower = body.lower()
    seen = set(exclude_lemmas)
    matches = []
    for word in Word.objects.filter(is_active=True, cefr_level__in=_ALLOWED_EXTRA_LEVELS):
        lemma_lower = word.lemma.lower()
        if lemma_lower in seen or lemma_lower not in body_lower:
            continue
        if re.search(rf"\b{re.escape(lemma_lower)}\b", body_lower):
            seen.add(lemma_lower)
            matches.append(word)
    return matches


class StorySerializer(serializers.ModelSerializer):
    """Read-only projection of a [Story] for the Home feed (FR-08 groundwork).

    Only the fields Home actually renders — the full `body` (needed for the
    detail view, FR-09) is out of scope until My Stories/Detail ship.
    """

    snippet = serializers.SerializerMethodField()
    words = serializers.SerializerMethodField()

    class Meta:
        model = Story
        fields = ["id", "title", "snippet", "words", "created_at"]

    def get_snippet(self, story: Story) -> str:
        body = story.body.strip()
        if len(body) <= SNIPPET_LENGTH:
            return body
        return body[:SNIPPET_LENGTH].rsplit(" ", 1)[0] + "…"

    def get_words(self, story: Story) -> list[str]:
        return [word.lemma for word in story.words.all()]


class StoryDetailSerializer(serializers.ModelSerializer):
    """Full projection of a [Story] for the Detail screen (FR-09).

    `words` are the target words the story was generated from; `extra_words`
    are other vocabulary-bank words (A2+) the LLM happened to use without
    being asked to. Both carry `cefr_level` (client-side highlight filtering)
    and definitions (shown when a highlighted word is tapped).
    """

    words = serializers.SerializerMethodField()
    extra_words = serializers.SerializerMethodField()

    class Meta:
        model = Story
        fields = ["id", "title", "body", "words", "extra_words", "created_at"]

    def get_words(self, story: Story) -> list[dict]:
        return [_word_payload(word) for word in story.words.all()]

    def get_extra_words(self, story: Story) -> list[dict]:
        used_lemmas = {word.lemma.lower() for word in story.words.all()}
        return [
            _word_payload(word)
            for word in _incidental_words(story.body, used_lemmas)
        ]
