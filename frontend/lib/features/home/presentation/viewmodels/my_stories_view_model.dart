import 'package:flutter/foundation.dart';

import '../../../../core/result.dart';
import '../../domain/home_repository.dart';
import '../../domain/models/story_summary.dart';

enum StorySortMode { recent, titleAz, mostWords }

/// Drives the My Stories screen: the full list of the user's own stories
/// with client-side search (FR-19) and sort (FR-20) — the dataset is small
/// enough that there's no need for a server round trip per keystroke or
/// chip tap.
class MyStoriesViewModel extends ChangeNotifier {
  MyStoriesViewModel(this._repository) {
    load();
  }

  final HomeRepository _repository;

  bool isLoading = true;
  String? errorMessage;
  List<StorySummary> _stories = const [];

  String searchQuery = '';
  StorySortMode sortMode = StorySortMode.recent;

  int get storyCount => _stories.length;

  List<StorySummary> get visibleStories {
    final query = searchQuery.trim().toLowerCase();
    final filtered = query.isEmpty
        ? _stories
        : _stories
              .where(
                (story) =>
                    story.title.toLowerCase().contains(query) ||
                    story.words.any(
                      (word) => word.toLowerCase().contains(query),
                    ),
              )
              .toList();

    final sorted = List<StorySummary>.of(filtered);
    switch (sortMode) {
      case StorySortMode.recent:
        sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case StorySortMode.titleAz:
        sorted.sort((a, b) => a.title.compareTo(b.title));
      case StorySortMode.mostWords:
        sorted.sort((a, b) => b.words.length.compareTo(a.words.length));
    }
    return sorted;
  }

  void setSearchQuery(String value) {
    searchQuery = value;
    notifyListeners();
  }

  void setSortMode(StorySortMode mode) {
    sortMode = mode;
    notifyListeners();
  }

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    switch (await _repository.fetchMyStories()) {
      case Ok(value: final stories):
        _stories = stories;
      case Err(message: final message):
        errorMessage = message;
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> retry() => load();
}
