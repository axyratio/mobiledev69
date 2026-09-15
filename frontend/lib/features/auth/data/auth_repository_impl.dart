import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/auth/session_store.dart';
import '../../../core/config/app_config.dart';
import '../../../core/result.dart';
import '../domain/auth_repository.dart';
import '../domain/models/session_user.dart';
import 'dtos/session_user_dto.dart';

/// Talks to the Django session-cookie API through [ApiClient] and maps its
/// JSON responses to domain models, converting every failure into a
/// [Result.err] instead of letting a [DioException] escape to the
/// ViewModel layer.
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._apiClient, this._sessionStore);

  final ApiClient _apiClient;
  final SessionStore _sessionStore;

  @override
  Future<Result<SessionUser?>> fetchCurrentUser() async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>(AppConfig.currentUserUrl);
      final body = response.data ?? const <String, dynamic>{};
      if (body['is_authenticated'] != true) return const Result.ok(null);
      return Result.ok(SessionUserDto.fromJson(body).toDomain());
    } catch (_) {
      return const Result.ok(null);
    }
  }

  @override
  Future<Result<SessionUser>> login({required String email, required String password}) {
    return _postForUser(AppConfig.loginUrl, {'email': email, 'password': password});
  }

  @override
  Future<Result<SessionUser>> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) {
    return _postForUser(AppConfig.registerUrl, {
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'password': password,
    });
  }

  Future<Result<SessionUser>> _postForUser(String url, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.post<Map<String, dynamic>>(url, data: data);
      final body = response.data ?? const <String, dynamic>{};
      if (response.statusCode != null && response.statusCode! >= 400) {
        return Result.err(body['detail'] as String? ?? 'Something went wrong. Please try again.');
      }
      return Result.ok(SessionUserDto.fromJson(body).toDomain());
    } catch (_) {
      return const Result.err('Could not reach the server. Please try again.');
    }
  }

  @override
  Future<Result<void>> logout() async {
    try {
      await _apiClient.dio.get<void>(
        AppConfig.logoutUrl,
        options: Options(followRedirects: false, validateStatus: (status) => true),
      );
      await _sessionStore.clear();
      return const Result.ok(null);
    } catch (_) {
      return const Result.err('Could not log out. Please try again.');
    }
  }
}
