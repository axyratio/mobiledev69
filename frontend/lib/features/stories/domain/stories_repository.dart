import '../../../core/result.dart';
import 'models/story_detail.dart';
import 'models/vocab_word.dart';

/// Contract the create-story and story-detail ViewModels depend on. The
/// concrete implementation ([StoriesRepositoryImpl], in the data layer) is
/// provided via DI (see `app.dart`).
abstract class StoriesRepository {
  /// Random vocabulary words for the create-story flow (FR-05). Pass
  /// [excludeIds] to avoid repeating words already shown, e.g. when
  /// re-rolling a single word with `count: 1`.
  Future<Result<List<VocabWord>>> fetchRandomWords(
    int count, {
    List<int> excludeIds = const [],
  });

  /// Vocabulary words matching [query], so a user can hand-pick which words
  /// to use instead of relying on the random sample.
  Future<Result<List<VocabWord>>> searchWords(String query);

  /// Calls the LLM with the confirmed words and persists the result
  /// (FR-06, FR-07). [genre] is optional and, when provided, must be one of
  /// the allowlisted genre chips the create-story screen offers.
  /// [paragraphCount] controls how many paragraphs the story is split into.
  Future<Result<StoryDetail>> generateStory({
    required List<int> wordIds,
    String? genre,
    int paragraphCount = 1,
  });

  /// The full text of a single owned story (FR-09).
  Future<Result<StoryDetail>> fetchStory(int id);
}
