import 'package:flutter/foundation.dart';

import '../../../../core/result.dart';
import '../../domain/home_repository.dart';
import '../../domain/models/story_summary.dart';

const _recentPreviewCount = 2;

/// Drives the Home dashboard (mockup 1a): a create-story hero, quick stats,
/// today's word sample, and a small preview of the most recent stories.
/// The full searchable/sortable list lives on My Stories instead
/// (FR-19/FR-20) — this screen is a launchpad, not the list itself.
class HomeViewModel extends ChangeNotifier {
  HomeViewModel(this._repository) {
    load();
  }

  final HomeRepository _repository;

  bool isLoading = true;
  String? errorMessage;
  List<StorySummary> _stories = const [];
  List<String> todayWords = const [];

  int get storyCount => _stories.length;

  /// Every distinct word used across the user's stories so far — a simple
  /// "vocabulary covered" count for the stats row.
  int get wordsUsedCount {
    final unique = <String>{};
    for (final story in _stories) {
      unique.addAll(story.words);
    }
    return unique.length;
  }

  /// The most recent stories, already sorted newest-first by the API.
  List<StorySummary> get recentStories =>
      _stories.take(_recentPreviewCount).toList();

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
