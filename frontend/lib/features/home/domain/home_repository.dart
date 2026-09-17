import '../../../core/result.dart';
import 'models/story_summary.dart';

/// Contract the Home ViewModel depends on. The concrete implementation
/// ([HomeRepositoryImpl], in the data layer) is provided via DI (see
/// `app.dart`), so the ViewModel never talks to [ApiClient] directly.
abstract class HomeRepository {
  /// The signed-in user's own stories (FR-08 groundwork), most recent first.
  Future<Result<List<StorySummary>>> fetchMyStories();

  /// A small daily sample of vocabulary words, available even to guests.
  Future<Result<List<String>>> fetchTodayWords();
}
