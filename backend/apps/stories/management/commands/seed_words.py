import json
from pathlib import Path

from django.core.management.base import BaseCommand, CommandParser
from django.db import transaction

from apps.stories.models import Word

DEFAULT_DATA_FILE = (
    Path(__file__).resolve().parents[4] / "data" / "oxford3000_sample.json"
)


class Command(BaseCommand):
    """Seeds the Word table from a JSON file containing a flat list of words."""

    help = "Seed vocabulary words into the database from a JSON word list."

    def add_arguments(self, parser: CommandParser) -> None:
        parser.add_argument(
            "--file",
            type=str,
            default=str(DEFAULT_DATA_FILE),
            help="Path to a JSON file containing a list of words.",
        )

    def handle(self, *args, **options) -> None:
        file_path = Path(options["file"])
        if not file_path.exists():
            self.stderr.write(self.style.ERROR(f"Word list not found: {file_path}"))
            return

        raw_words = json.loads(file_path.read_text(encoding="utf-8"))
        created_count = self._seed_words(raw_words)
        self.stdout.write(
            self.style.SUCCESS(
                f"Seeded {created_count} new word(s) out of {len(raw_words)} in the file."
            )
        )

    @transaction.atomic
    def _seed_words(self, raw_words: list[str]) -> int:
        """Inserts words not already present, skipping duplicates case-insensitively."""
        existing_words = set(Word.objects.values_list("word", flat=True))
        normalized_words = {w.strip().lower() for w in raw_words if w.strip()}
        new_words = [
            Word(word=word, source="oxford3000")
            for word in normalized_words
            if word not in existing_words
        ]
        Word.objects.bulk_create(new_words, ignore_conflicts=True)
        return len(new_words)
