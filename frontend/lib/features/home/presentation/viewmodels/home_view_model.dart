import 'package:flutter/foundation.dart';

import '../../../../core/result.dart';
import '../../domain/home_repository.dart';
import '../../domain/models/story_summary.dart';

enum StorySortMode { recent, titleAz, mostWords }

/// Drives the Home feed (mockup 1b): loads the signed-in user's stories plus
/// today's word sample, then applies the search/sort chips client-side —
/// the dataset is small enough that there's no need for a server round trip
/// per keystroke or chip tap.
class HomeViewModel extends ChangeNotifier {
  HomeViewModel(this._repository) {
    load();
  }

  final HomeRepository _repository;

  bool isLoading = true;
  String? errorMessage;
  List<StorySummary> _stories = const [];
  List<String> todayWords = const [];

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

    final results = await Future.wait([
      _repository.fetchMyStories(),
      _repository.fetchTodayWords(),
    ]);

    switch (results[0] as Result<List<StorySummary>>) {
      case Ok(value: final stories):
        _stories = stories;
      case Err(message: final message):
        errorMessage = message;
    }
    switch (results[1] as Result<List<String>>) {
      case Ok(value: final words):
        todayWords = words;
      case Err():
        todayWords = const [];
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> retry() => load();
}
