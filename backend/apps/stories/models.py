from django.conf import settings
from django.db import models


class Word(models.Model):
    """A single vocabulary entry seeded from a word bank (e.g. Oxford 3000)."""

    word = models.CharField(max_length=100, unique=True)
    source = models.CharField(max_length=100, default="oxford3000")

    class Meta:
        ordering = ["word"]

    def __str__(self) -> str:
        return self.word


class Story(models.Model):
    """An AI-generated short story, owned by exactly one user (FR-07, FR-12)."""

    owner = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="stories",
    )
    title = models.CharField(max_length=200)
    body = models.TextField()
    prompt_used = models.TextField(blank=True, default="")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    words = models.ManyToManyField(Word, through="StoryWord", related_name="stories")

    class Meta:
        ordering = ["-created_at"]
        indexes = [
            models.Index(fields=["owner", "-created_at"]),
            models.Index(fields=["owner", "title"]),
        ]

    def __str__(self) -> str:
        return self.title


class StoryWord(models.Model):
    """Records which seeded words were actually used in a given story (FR-09).

    `on_delete=models.CASCADE` on both foreign keys guarantees that deleting a
    Story removes its StoryWord rows in the same transaction, satisfying
    NFR-06 (no orphan StoryWord records).
    """

    story = models.ForeignKey(Story, on_delete=models.CASCADE, related_name="story_words")
    word = models.ForeignKey(Word, on_delete=models.CASCADE, related_name="story_words")

    class Meta:
        constraints = [
            models.UniqueConstraint(fields=["story", "word"], name="unique_story_word")
        ]

    def __str__(self) -> str:
        return f"{self.story_id}:{self.word.word}"
