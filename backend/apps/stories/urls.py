from django.urls import path

from .views import (
    StoryListView,
    generate_story_view,
    random_words_view,
    story_detail_view,
    words_search_view,
    words_today_view,
)

urlpatterns = [
    path("stories/", StoryListView.as_view(), name="story-list"),
    path("stories/generate/", generate_story_view, name="story-generate"),
    path("stories/<int:pk>/", story_detail_view, name="story-detail"),
    path("words/today/", words_today_view, name="words-today"),
    path("words/random/", random_words_view, name="words-random"),
    path("words/search/", words_search_view, name="words-search"),
]
