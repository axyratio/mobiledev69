import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/config/app_config.dart';
import '../../../core/result.dart';
import '../domain/models/story_detail.dart';
import '../domain/models/vocab_word.dart';
import '../domain/stories_repository.dart';
import 'dtos/story_detail_dto.dart';
import 'dtos/vocab_word_dto.dart';

/// Talks to the Django API through [ApiClient], converting every failure
/// into a [Result.err] with a message the UI can show directly (FR-13,
/// FR-14) instead of letting a [DioException] escape to the ViewModel.
class StoriesRepositoryImpl implements StoriesRepository {
  StoriesRepositoryImpl(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<Result<List<VocabWord>>> fetchRandomWords(
    int count, {
    List<int> excludeIds = const [],
  }) async {
    try {
      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        AppConfig.wordsRandomUrl,
        data: {'count': count, 'exclude_ids': excludeIds},
      );
      if (_isError(response.statusCode)) {
        return Result.err(
          _detailFrom(response, fallback: 'สุ่มคำศัพท์ไม่สำเร็จ'),
        );
      }
      final words = (response.data?['words'] as List<dynamic>? ?? const [])
          .cast<Map<String, dynamic>>()
          .map((json) => VocabWordDto.fromJson(json).toDomain())
          .toList();
      return Result.ok(words);
    } catch (_) {
      return const Result.err('ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้ กรุณาลองใหม่');
    }
  }

  @override
  Future<Result<List<VocabWord>>> searchWords(String query) async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        AppConfig.wordsSearchUrl,
        queryParameters: {'q': query},
      );
      if (_isError(response.statusCode)) {
        return Result.err(
          _detailFrom(response, fallback: 'ค้นหาคำศัพท์ไม่สำเร็จ'),
        );
      }
      final words = (response.data?['words'] as List<dynamic>? ?? const [])
          .cast<Map<String, dynamic>>()
          .map((json) => VocabWordDto.fromJson(json).toDomain())
          .toList();
      return Result.ok(words);
    } catch (_) {
      return const Result.err('ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้ กรุณาลองใหม่');
    }
  }

  @override
  Future<Result<StoryDetail>> generateStory({
    required List<int> wordIds,
    String? genre,
    int paragraphCount = 1,
  }) async {
    try {
      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        AppConfig.storiesGenerateUrl,
        data: {
          'word_ids': wordIds,
          'paragraph_count': paragraphCount,
          if (genre != null) 'genre': genre,
        },
      );
      if (_isError(response.statusCode)) {
        return Result.err(
          _detailFrom(response, fallback: 'เชื่อมต่อ AI ไม่สำเร็จ'),
        );
      }
      return Result.ok(StoryDetailDto.fromJson(response.data!).toDomain());
    } catch (_) {
      return const Result.err('เชื่อมต่อ AI ไม่สำเร็จ');
    }
  }

  @override
  Future<Result<StoryDetail>> fetchStory(int id) async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        AppConfig.storyDetailUrl(id),
      );
      if (_isError(response.statusCode)) {
        return Result.err(_detailFrom(response, fallback: 'ไม่พบเรื่องนี้'));
      }
      return Result.ok(StoryDetailDto.fromJson(response.data!).toDomain());
    } catch (_) {
      return const Result.err('ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้ กรุณาลองใหม่');
    }
  }

  @override
  Future<Result<StoryDetail>> renameStory(int id, String title) async {
    try {
      final response = await _apiClient.dio.patch<Map<String, dynamic>>(
        AppConfig.storyDetailUrl(id),
        data: {'title': title},
      );
      if (_isError(response.statusCode)) {
        return Result.err(
          _detailFrom(response, fallback: 'บันทึกชื่อเรื่องไม่สำเร็จ'),
        );
      }
      return Result.ok(StoryDetailDto.fromJson(response.data!).toDomain());
    } catch (_) {
      return const Result.err('ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้ กรุณาลองใหม่');
    }
  }

  @override
  Future<Result<void>> deleteStory(int id) async {
    try {
      final response = await _apiClient.dio.delete<Map<String, dynamic>>(
        AppConfig.storyDetailUrl(id),
      );
      if (_isError(response.statusCode)) {
        return Result.err(_detailFrom(response, fallback: 'ลบเรื่องไม่สำเร็จ'));
      }
      return const Result.ok(null);
    } catch (_) {
      return const Result.err('ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้ กรุณาลองใหม่');
    }
  }

  bool _isError(int? statusCode) => statusCode != null && statusCode >= 400;

  String _detailFrom(
    Response<Map<String, dynamic>> response, {
    required String fallback,
  }) {
    final detail = response.data?['detail'];
    return detail is String && detail.isNotEmpty ? detail : fallback;
  }
}
