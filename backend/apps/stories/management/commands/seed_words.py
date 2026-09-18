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
        # update_or_create per row (~2 round trips/row) is fine against local
        # sqlite but crawls against a remote Postgres instance (thousands of
        # network round trips). Batch everything into a handful of bulk
        # queries instead, regardless of row count.
        word_defaults: dict[tuple[str, str], dict] = {}
        forms_by_word_key: dict[tuple[str, str], dict[str, str]] = {}

        for row in rows:
            lemma = row["lemma"].strip()
            pos = row["pos"].strip()
            form = row["form"].strip().lower()
            if not lemma or not pos or not form:
                continue

            word_key = (lemma, pos)
            if word_key not in word_defaults:
                word_defaults[word_key] = {
                    "word_type": row["word_type"].strip() or Word.WordType.SINGLE,
                    "cefr_level": row["cefr_level"].strip(),
                    "definition_en": row["definition_en"].strip(),
                    "definition_th": row["definition_th"].strip(),
                    "source": row["source"].strip() or "oxford3000",
                    "is_active": True,
                }
            forms_by_word_key.setdefault(word_key, {})[form] = row["form_type"].strip()

        existing_words = {(w.lemma, w.pos): w for w in Word.objects.all()}

        to_create_items = [
            (key, Word(lemma=key[0], pos=key[1], **defaults))
            for key, defaults in word_defaults.items()
            if key not in existing_words
        ]
        Word.objects.bulk_create([w for _, w in to_create_items], batch_size=1000)

        word_lookup = dict(existing_words)
        word_lookup.update(to_create_items)

        word_fields = ["word_type", "cefr_level", "definition_en", "definition_th", "source", "is_active"]
        to_update_words = []
        for key, word in existing_words.items():
            for field, value in word_defaults[key].items():
                setattr(word, field, value)
            to_update_words.append(word)
        if to_update_words:
            Word.objects.bulk_update(to_update_words, fields=word_fields, batch_size=1000)

        existing_forms = {
            (wf.word_id, wf.form): wf
            for wf in WordForm.objects.filter(word_id__in=[w.id for w in word_lookup.values()])
        }

        to_create_forms = []
        to_update_forms = []
        for key, forms in forms_by_word_key.items():
            word = word_lookup[key]
            for form, form_type in forms.items():
                form_key = (word.id, form)
                existing_form = existing_forms.get(form_key)
                if existing_form is None:
                    to_create_forms.append(WordForm(word=word, form=form, form_type=form_type))
                elif existing_form.form_type != form_type:
                    existing_form.form_type = form_type
                    to_update_forms.append(existing_form)

        WordForm.objects.bulk_create(to_create_forms, batch_size=1000)
        if to_update_forms:
            WordForm.objects.bulk_update(to_update_forms, fields=["form_type"], batch_size=1000)

        forms_seeded = sum(len(forms) for forms in forms_by_word_key.values())
        return len(word_defaults), forms_seeded
