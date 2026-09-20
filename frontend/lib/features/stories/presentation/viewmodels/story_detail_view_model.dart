import 'package:flutter/foundation.dart';

import '../../../../core/cefr/cefr_level.dart';
import '../../../../core/result.dart';
import '../../../../core/safe_change_notifier.dart';
import '../../domain/models/story_detail.dart';
import '../../domain/models/story_vocab_word.dart';
import '../../domain/stories_repository.dart';

/// Which language the Detail screen currently displays — the article body
/// and the word-definition sheet both read off this (FR-09 Thai toggle).
enum StoryLanguage { en, th }

/// Loads a single story for the Detail screen (FR-09). Accepts an optional
/// [preloaded] story (the one just returned by `generateStory`) so tapping
/// straight from the create flow doesn't re-fetch what's already in hand.
class StoryDetailViewModel extends ChangeNotifier with SafeChangeNotifier {
  StoryDetailViewModel(
    this._repository, {
    required int storyId,
    StoryDetail? preloaded,
    String initialLevel = 'A1',
    bool filterByLevel = true,
  }) : _storyId = storyId,
       selectedLevel = initialLevel,
       _filterByLevel = filterByLevel {
    if (preloaded != null) {
      story = preloaded;
      isLoading = false;
    } else {
      load();
    }
  }

  final StoriesRepository _repository;
  final int _storyId;

  bool isLoading = true;
  String? errorMessage;
  StoryDetail? story;

  /// Which language the body (and word definitions) are shown in. Toggled
  /// from the app bar; defaults to English since highlighting only applies
  /// to the English body.
  StoryLanguage language = StoryLanguage.en;

  void toggleLanguage() {
    language = language == StoryLanguage.en ? StoryLanguage.th : StoryLanguage.en;
    safeNotifyListeners();
  }

  /// The learner's CEFR level (set in Settings) — only target words at or
  /// above it are highlighted in the body.
  final String selectedLevel;

  /// Whether [selectedLevel] should limit highlighting at all ("highlight
  /// by my level" toggle in Settings). Off means every vocabulary-bank word
  /// found in the story is highlighted, regardless of level.
  final bool _filterByLevel;

  /// Target words to highlight in the body: those matching [selectedLevel]
  /// or above when the level filter is on, or all of them when it's off.
  List<String> get highlightedWords {
    final story = this.story;
    if (story == null) return const [];
    return story.words
        .where((word) => !_filterByLevel || cefrLevelMeetsSelection(word.cefrLevel, selectedLevel))
        .map((word) => word.word)
        .toList();
  }

  /// Bonus vocabulary the LLM happened to use (A2+ server-side floor),
  /// further filtered by [selectedLevel] just like [highlightedWords] so
  /// raising the level hides easy bonus words too — highlighted in a
  /// different color than target words. Unfiltered when the level filter
  /// is off.
  List<String> get extraHighlightedWords {
    final story = this.story;
    if (story == null) return const [];
    return story.extraWords
        .where((word) => !_filterByLevel || cefrLevelMeetsSelection(word.cefrLevel, selectedLevel))
        .map((word) => word.word)
        .toList();
  }

  /// Looks up the full word entry (for its definition) by the text as it
  /// appeared in the body — matching is case-insensitive since highlighting
  /// itself is.
  StoryVocabWord? findWord(String word) {
    final story = this.story;
    if (story == null) return null;
    final lower = word.toLowerCase();
    for (final candidate in [...story.words, ...story.extraWords]) {
      if (candidate.word.toLowerCase() == lower) return candidate;
    }
    return null;
  }

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    final result = await _repository.fetchStory(_storyId);
    switch (result) {
      case Ok(value: final loaded):
        story = loaded;
      case Err(message: final message):
        errorMessage = message;
    }

    isLoading = false;
    safeNotifyListeners();
  }

  Future<void> retry() => load();

  /// Renames the story (FR-10, FR-12). On success, updates [story] in place
  /// so the header reflects the new title without a re-fetch.
  Future<Result<void>> rename(String title) async {
    final result = await _repository.renameStory(_storyId, title);
    switch (result) {
      case Ok(value: final updated):
        story = updated;
        safeNotifyListeners();
        return const Result.ok(null);
      case Err(message: final message):
        return Result.err(message);
    }
  }

  /// Permanently deletes the story (FR-11, NFR-06).
  Future<Result<void>> delete() => _repository.deleteStory(_storyId);
}
