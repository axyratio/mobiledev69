import '../../../core/api/api_client.dart';
import '../../../core/config/app_config.dart';
import '../../../core/result.dart';
import '../domain/home_repository.dart';
import '../domain/models/story_summary.dart';
import 'dtos/story_dto.dart';

/// Talks to the Django API through [ApiClient] and maps its JSON responses
/// to domain models, converting every failure into a [Result.err] instead of
/// letting a [DioException] escape to the ViewModel layer.
class HomeRepositoryImpl implements HomeRepository {
  HomeRepositoryImpl(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<Result<List<StorySummary>>> fetchMyStories() async {
    try {
      final response = await _apiClient.dio.get<List<dynamic>>(
        AppConfig.storiesUrl,
      );
      if (response.statusCode != null && response.statusCode! >= 400) {
        return const Result.err(
          'Could not load your stories. Please try again.',
        );
      }
      final stories = (response.data ?? const [])
          .cast<Map<String, dynamic>>()
          .map((json) => StoryDto.fromJson(json).toDomain())
          .toList();
      return Result.ok(stories);
    } catch (_) {
      return const Result.err('Could not reach the server. Please try again.');
    }
  }

  @override
  Future<Result<List<String>>> fetchTodayWords() async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        AppConfig.wordsTodayUrl,
      );
      if (response.statusCode != null && response.statusCode! >= 400) {
        return const Result.err("Could not load today's words.");
      }
      final words = (response.data?['words'] as List<dynamic>? ?? const [])
          .cast<String>();
      return Result.ok(words);
    } catch (_) {
      return const Result.err('Could not reach the server. Please try again.');
    }
  }
}
