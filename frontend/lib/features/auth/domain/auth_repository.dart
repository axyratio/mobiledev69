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
}
