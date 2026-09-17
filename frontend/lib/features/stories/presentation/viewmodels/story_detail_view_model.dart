import 'package:flutter/foundation.dart';

import '../../../../core/cefr/cefr_level.dart';
import '../../../../core/result.dart';
import '../../domain/models/story_detail.dart';
import '../../domain/models/story_vocab_word.dart';
import '../../domain/stories_repository.dart';

/// Loads a single story for the Detail screen (FR-09). Accepts an optional
/// [preloaded] story (the one just returned by `generateStory`) so tapping
/// straight from the create flow doesn't re-fetch what's already in hand.
class StoryDetailViewModel extends ChangeNotifier {
  StoryDetailViewModel(
    this._repository, {
    required int storyId,
    StoryDetail? preloaded,
    String initialLevel = 'A1',
  }) : _storyId = storyId,
       selectedLevel = initialLevel {
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

  /// The learner's CEFR level (set in Settings) — only target words at or
  /// above it are highlighted in the body.
  final String selectedLevel;

  /// Target words to highlight in the body: those matching [selectedLevel]
  /// or above (words below it are treated as already known).
  List<String> get highlightedWords {
    final story = this.story;
    if (story == null) return const [];
    return story.words
        .where((word) => cefrLevelMeetsSelection(word.cefrLevel, selectedLevel))
        .map((word) => word.word)
        .toList();
  }

  /// Bonus vocabulary the LLM happened to use (A2+ server-side floor),
  /// further filtered by [selectedLevel] just like [highlightedWords] so
  /// raising the level hides easy bonus words too — highlighted in a
  /// different color than target words.
  List<String> get extraHighlightedWords {
    final story = this.story;
    if (story == null) return const [];
    return story.extraWords
        .where((word) => cefrLevelMeetsSelection(word.cefrLevel, selectedLevel))
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
    notifyListeners();
  }

  Future<void> retry() => load();
}
