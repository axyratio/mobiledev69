from django.contrib import admin

from apps.stories.models import Story, StoryWord, Word, WordForm


@admin.register(Word)
class WordAdmin(admin.ModelAdmin):
    list_display = ("lemma", "pos", "cefr_level", "word_type", "is_active", "source")
    search_fields = ("lemma",)
    list_filter = ("pos", "cefr_level", "word_type", "is_active", "source")


@admin.register(WordForm)
class WordFormAdmin(admin.ModelAdmin):
    list_display = ("form", "word", "form_type")
    search_fields = ("form", "word__lemma")
    list_filter = ("form_type",)


class StoryWordInline(admin.TabularInline):
    model = StoryWord
    extra = 0


@admin.register(Story)
class StoryAdmin(admin.ModelAdmin):
    list_display = ("title", "owner", "created_at", "updated_at")
    search_fields = ("title", "owner__email")
    list_filter = ("created_at",)
    inlines = [StoryWordInline]
