import 'package:flutter/foundation.dart';

import '../../../../core/result.dart';
import '../../domain/models/story_detail.dart';
import '../../domain/stories_repository.dart';

/// Loads a single story for the Detail screen (FR-09). Accepts an optional
/// [preloaded] story (the one just returned by `generateStory`) so tapping
/// straight from the create flow doesn't re-fetch what's already in hand.
class StoryDetailViewModel extends ChangeNotifier {
  StoryDetailViewModel(
    this._repository, {
    required int storyId,
    StoryDetail? preloaded,
  }) : _storyId = storyId {
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
