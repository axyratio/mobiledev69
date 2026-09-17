import 'package:flutter/foundation.dart';

import '../../../../core/result.dart';
import '../../domain/models/story_detail.dart';
import '../../domain/models/vocab_word.dart';
import '../../domain/stories_repository.dart';

enum CreateStoryStep { pickCount, reviewWords, generating, error }

/// How the create-story wizard picks its words on step 1.
enum WordSelectionMode { random, manual }

/// Genre chips offered on step 1 (mockup 1e) — kept as a fixed, allowlisted
/// set (mirrors the backend's `ALLOWED_GENRES`) rather than free text, so
/// there's nothing here for a prompt-injection payload to ride in on.
const List<String> createStoryGenres = ['ลึกลับ', 'อบอุ่น', 'ตลก', 'ไซไฟ'];

const int minStoryWords = 3;
const int maxStoryWords = 15;

const int minStoryParagraphs = 1;
const int maxStoryParagraphs = 5;

/// Drives the create-story wizard (FR-04 through FR-07, FR-13, NFR-01):
/// pick a word count -> review the random words -> call the LLM -> land on
/// the saved story, with a re-roll (whole set or one word) available on the
/// review step and a retry available if generation fails.
class CreateStoryViewModel extends ChangeNotifier {
  CreateStoryViewModel(this._repository);

  final StoriesRepository _repository;

  CreateStoryStep step = CreateStoryStep.pickCount;
  int wordCount = 5;
  int paragraphCount = 1;
  String? genre;
  List<VocabWord> words = const [];
  String? errorMessage;
  bool isBusy = false;
  StoryDetail? createdStory;

  WordSelectionMode wordSelectionMode = WordSelectionMode.random;
  String searchQuery = '';
  List<VocabWord> searchResults = const [];
  List<VocabWord> selectedWords = const [];
  bool isSearching = false;

  bool get isCountValid =>
      wordCount >= minStoryWords && wordCount <= maxStoryWords;

  bool get isManualSelectionComplete => selectedWords.length == wordCount;

  bool get canConfirmPick =>
      isCountValid &&
      (wordSelectionMode == WordSelectionMode.random ||
          isManualSelectionComplete);

  void setWordCount(int value) {
    wordCount = value;
    if (selectedWords.length > value) {
      selectedWords = selectedWords.take(value).toList();
    }
    notifyListeners();
  }

  void setParagraphCount(int value) {
    paragraphCount = value;
    notifyListeners();
  }

  void selectGenre(String value) {
    genre = genre == value ? null : value;
    notifyListeners();
  }

  void setWordSelectionMode(WordSelectionMode mode) {
    if (wordSelectionMode == mode) return;
    wordSelectionMode = mode;
    searchQuery = '';
    searchResults = const [];
    selectedWords = const [];
    notifyListeners();
  }

  /// A word is selectable when there's still room, or it's already picked
  /// (so unticking it is always allowed even once the cap is reached).
  bool isWordSelectable(VocabWord word) =>
      isWordSelected(word) || selectedWords.length < wordCount;

  bool isWordSelected(VocabWord word) =>
      selectedWords.any((selected) => selected.id == word.id);

  void toggleWordSelection(VocabWord word) {
    if (isWordSelected(word)) {
      selectedWords = selectedWords
          .where((selected) => selected.id != word.id)
          .toList();
    } else if (selectedWords.length < wordCount) {
      selectedWords = [...selectedWords, word];
    } else {
      return;
    }
    notifyListeners();
  }

  Future<void> search(String query) async {
    searchQuery = query;
    if (query.trim().isEmpty) {
      searchResults = const [];
      notifyListeners();
      return;
    }

    isSearching = true;
    notifyListeners();

    final result = await _repository.searchWords(query.trim());
    switch (result) {
      case Ok(value: final results):
        searchResults = results;
      case Err(message: final message):
        errorMessage = message;
    }

    isSearching = false;
    notifyListeners();
  }

  Future<void> confirmCount() async {
    if (!canConfirmPick || isBusy) return;

    if (wordSelectionMode == WordSelectionMode.manual) {
      words = List.of(selectedWords);
      step = CreateStoryStep.reviewWords;
      notifyListeners();
      return;
    }

    isBusy = true;
    errorMessage = null;
    notifyListeners();

    final result = await _repository.fetchRandomWords(wordCount);
    switch (result) {
      case Ok(value: final fetchedWords):
        words = fetchedWords;
        step = CreateStoryStep.reviewWords;
      case Err(message: final message):
        errorMessage = message;
    }

    isBusy = false;
    notifyListeners();
  }

  Future<void> rerollAll() async {
    if (isBusy) return;
    isBusy = true;
    notifyListeners();

    final result = await _repository.fetchRandomWords(wordCount);
    switch (result) {
      case Ok(value: final fetchedWords):
        words = fetchedWords;
      case Err(message: final message):
        errorMessage = message;
    }

    isBusy = false;
    notifyListeners();
  }

  Future<void> rerollWordAt(int index) async {
    if (isBusy) return;
    isBusy = true;
    notifyListeners();

    final excludeIds = words.map((word) => word.id).toList();
    final result = await _repository.fetchRandomWords(
      1,
      excludeIds: excludeIds,
    );
    switch (result) {
      case Ok(value: final fetchedWords):
        if (fetchedWords.isNotEmpty) {
          words = [...words]..[index] = fetchedWords.first;
        }
      case Err(message: final message):
        errorMessage = message;
    }

    isBusy = false;
    notifyListeners();
  }

  Future<void> generate() async {
    step = CreateStoryStep.generating;
    errorMessage = null;
    notifyListeners();

    final result = await _repository.generateStory(
      wordIds: words.map((word) => word.id).toList(),
      genre: genre,
      paragraphCount: paragraphCount,
    );
    switch (result) {
      case Ok(value: final story):
        createdStory = story;
      case Err(message: final message):
        errorMessage = message;
        step = CreateStoryStep.error;
    }

    notifyListeners();
  }

  void backToCount() {
    step = CreateStoryStep.pickCount;
    errorMessage = null;
    notifyListeners();
  }

  Future<void> retryGenerate() => generate();

  /// Clears a transient fetch/re-roll error once its snackbar has been
  /// shown, so it doesn't reappear on the next rebuild.
  void clearError() {
    errorMessage = null;
  }
}
