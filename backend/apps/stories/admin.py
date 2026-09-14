from django.contrib import admin

from apps.stories.models import Story, StoryWord, Word


@admin.register(Word)
class WordAdmin(admin.ModelAdmin):
    list_display = ("word", "source")
    search_fields = ("word",)
    list_filter = ("source",)


class StoryWordInline(admin.TabularInline):
    model = StoryWord
    extra = 0


@admin.register(Story)
class StoryAdmin(admin.ModelAdmin):
    list_display = ("title", "owner", "created_at", "updated_at")
    search_fields = ("title", "owner__email")
    list_filter = ("created_at",)
    inlines = [StoryWordInline]
