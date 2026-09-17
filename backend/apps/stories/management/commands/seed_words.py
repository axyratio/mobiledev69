import csv
from pathlib import Path

from django.core.management.base import BaseCommand, CommandParser
from django.db import transaction

from apps.stories.models import Word, WordForm

DEFAULT_DATA_FILE = Path(__file__).resolve().parents[4] / "data" / "word.csv"

REQUIRED_COLUMNS = {
    "lemma",
    "pos",
    "cefr_level",
    "word_type",
    "definition_en",
    "definition_th",
    "source",
    "form",
    "form_type",
}


class Command(BaseCommand):
    """Seeds Word + WordForm from the Oxford 3000 CSV export (5.8 in
    requirement-core-extra.md).

    The CSV is denormalized: one row per (lemma, pos, form). Each row's
    lemma-level columns (word_type, cefr_level, definitions, source) are
    identical across every form of the same (lemma, pos), so they're
    upserted once into Word and every row's `form`/`form_type` becomes its
    own WordForm.
    """

    help = "Seed the Word and WordForm tables from the word bank CSV."

    def add_arguments(self, parser: CommandParser) -> None:
        parser.add_argument(
            "--file",
            type=str,
            default=str(DEFAULT_DATA_FILE),
            help="Path to the word bank CSV file.",
        )
        parser.add_argument(
            "--flush",
            action="store_true",
            help=(
                "Delete every existing Word (and its WordForm/StoryWord rows via "
                "cascade) before seeding, instead of upserting by (lemma, pos). "
                "Use this to clear out words seeded by an older word list."
            ),
        )

    def handle(self, *args, **options) -> None:
        file_path = Path(options["file"])
        if not file_path.exists():
            self.stderr.write(self.style.ERROR(f"Word bank CSV not found: {file_path}"))
            return

        if options["flush"]:
            deleted, _ = Word.objects.all().delete()
            self.stdout.write(self.style.WARNING(f"Deleted {deleted} existing row(s) before reseeding."))

        with file_path.open(encoding="utf-8-sig", newline="") as f:
            reader = csv.DictReader(f)
            missing = REQUIRED_COLUMNS - set(reader.fieldnames or [])
            if missing:
                self.stderr.write(
                    self.style.ERROR(f"CSV is missing required column(s): {', '.join(sorted(missing))}")
                )
                return
            rows = [row for row in reader]

        words_seeded, forms_seeded = self._seed(rows)
        self.stdout.write(
            self.style.SUCCESS(
                f"Seeded {words_seeded} word(s) and {forms_seeded} word form(s) from {len(rows)} CSV row(s)."
            )
        )

    @transaction.atomic
    def _seed(self, rows: list[dict]) -> tuple[int, int]:
        word_cache: dict[tuple[str, str], Word] = {}
        forms_seen: set[tuple[int, str]] = set()
        forms_seeded = 0

        for row in rows:
            lemma = row["lemma"].strip()
            pos = row["pos"].strip()
            form = row["form"].strip().lower()
            if not lemma or not pos or not form:
                continue

            word_key = (lemma, pos)
            word = word_cache.get(word_key)
            if word is None:
                word, _ = Word.objects.update_or_create(
                    lemma=lemma,
                    pos=pos,
                    defaults={
                        "word_type": row["word_type"].strip() or Word.WordType.SINGLE,
                        "cefr_level": row["cefr_level"].strip(),
                        "definition_en": row["definition_en"].strip(),
                        "definition_th": row["definition_th"].strip(),
                        "source": row["source"].strip() or "oxford3000",
                        "is_active": True,
                    },
                )
                word_cache[word_key] = word

            form_key = (word.id, form)
            if form_key in forms_seen:
                continue
            forms_seen.add(form_key)

            WordForm.objects.update_or_create(
                word=word,
                form=form,
                defaults={"form_type": row["form_type"].strip()},
            )
            forms_seeded += 1

        return len(word_cache), forms_seeded
