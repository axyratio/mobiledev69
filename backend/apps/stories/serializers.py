from rest_framework import serializers

from .models import Story

SNIPPET_LENGTH = 140


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
        return [word.word for word in story.words.all()]


class StoryDetailSerializer(serializers.ModelSerializer):
    """Full projection of a [Story] for the Detail screen (FR-09)."""

    words = serializers.SerializerMethodField()

    class Meta:
        model = Story
        fields = ["id", "title", "body", "words", "created_at"]

    def get_words(self, story: Story) -> list[str]:
        return [word.word for word in story.words.all()]
