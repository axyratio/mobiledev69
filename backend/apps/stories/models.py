from django.conf import settings
from django.db import models


class Word(models.Model):
    """A single vocabulary entry seeded from a word bank (e.g. Oxford 3000).

    One row = one lemma + one part of speech, matching the spelling-per-POS
    layout Oxford 3000 ships with (e.g. `access` as noun and `access` as verb
    are two separate rows).
    """

    class WordType(models.TextChoices):
        SINGLE = "single", "Single"
        PHRASE = "phrase", "Phrase"

    class PartOfSpeech(models.TextChoices):
        NOUN = "noun", "Noun"
        VERB = "verb", "Verb"
        ADJ = "adj", "Adjective"
        ADV = "adv", "Adverb"
        PREP = "prep", "Preposition"
        CONJ = "conj", "Conjunction"
        PRON = "pron", "Pronoun"
        DET = "det", "Determiner"
        NUMBER = "number", "Number"
        EXCLAM = "exclam", "Exclamation"
        OTHER = "other", "Other"

    class CefrLevel(models.TextChoices):
        A1 = "A1", "A1"
        A2 = "A2", "A2"
        B1 = "B1", "B1"
        B2 = "B2", "B2"

    lemma = models.CharField(max_length=128)
    word_type = models.CharField(max_length=10, choices=WordType.choices, default=WordType.SINGLE)
    pos = models.CharField(max_length=10, choices=PartOfSpeech.choices)
    cefr_level = models.CharField(max_length=2, choices=CefrLevel.choices)
    definition_en = models.TextField(blank=True, default="")
    definition_th = models.TextField(blank=True, default="")
    example = models.TextField(blank=True, default="")
    source = models.CharField(max_length=32, default="oxford3000")
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["lemma"]
        constraints = [
            models.UniqueConstraint(fields=["lemma", "pos"], name="unique_word_lemma_pos"),
        ]
        indexes = [
            models.Index(fields=["cefr_level", "is_active"]),
        ]

    def __str__(self) -> str:
        return self.lemma


class WordForm(models.Model):
    """An inflected surface form of a [Word], used to match what the LLM
    actually wrote back to the seeded lemma (FR-09).

    The LLM almost never echoes a word back in its lemma form (asked for
    `run`, it writes `ran`), so highlighting has to search for every known
    form instead of the bare lemma.
    """

    class FormType(models.TextChoices):
        BASE = "base", "Base"
        PLURAL = "plural", "Plural"
        PAST = "past", "Past"
        PAST_PARTICIPLE = "past_participle", "Past participle"
        GERUND = "gerund", "Gerund"
        THIRD_PERSON = "third_person", "Third person"
        COMPARATIVE = "comparative", "Comparative"
        SUPERLATIVE = "superlative", "Superlative"

    word = models.ForeignKey(Word, on_delete=models.CASCADE, related_name="forms")
    form = models.CharField(max_length=128)
    form_type = models.CharField(max_length=20, choices=FormType.choices)

    class Meta:
        constraints = [
            models.UniqueConstraint(fields=["word", "form"], name="unique_word_form"),
        ]
        indexes = [
            models.Index(fields=["form"]),
        ]

    def __str__(self) -> str:
        return self.form


class Story(models.Model):
    """An AI-generated short story, owned by exactly one user (FR-07, FR-12)."""

    owner = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="stories",
    )
    title = models.CharField(max_length=200)
    body = models.TextField()
    title_th = models.CharField(max_length=200, blank=True, default="")
    body_th = models.TextField(blank=True, default="")
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
        return f"{self.story_id}:{self.word.lemma}"
