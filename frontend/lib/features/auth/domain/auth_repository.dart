import '../../../core/result.dart';
import 'models/session_user.dart';

/// Contract the presentation layer (ViewModels) depends on. The concrete
/// implementation ([AuthRepositoryImpl], in the data layer) is provided via
/// DI (see `app.dart`), so ViewModels never talk to [ApiClient] directly.
abstract class AuthRepository {
  /// The current session's user, or null if there is no valid session.
  Future<Result<SessionUser?>> fetchCurrentUser();

  Future<Result<SessionUser>> login({required String email, required String password});

  Future<Result<SessionUser>> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  });

  Future<Result<void>> logout();

  /// Persists the learner's chosen theme (FR-17/FR-18 Dark Mode), so it's
  /// remembered on every future visit instead of resetting each session.
  Future<Result<SessionUser>> updateThemePreference(String theme);

  /// Persists the learner's chosen CEFR level (Story Detail highlight
  /// filter), so it's remembered on every future visit.
  Future<Result<SessionUser>> updateCefrLevel(String level);

  /// Persists whether the create-story word randomizer should be limited
  /// to the learner's own CEFR level and below.
  Future<Result<SessionUser>> updateCefrLevelFilterEnabled(bool enabled);

  /// Persists whether Story Detail highlighting should be limited to the
  /// learner's own CEFR level and above.
  Future<Result<SessionUser>> updateHighlightFilterByLevelEnabled(bool enabled);
}
