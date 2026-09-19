import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/api/api_client.dart';
import 'core/auth/session_store.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'features/auth/data/auth_repository_impl.dart';
import 'features/auth/domain/auth_repository.dart';
import 'features/auth/presentation/viewmodels/auth_view_model.dart';
import 'features/home/data/home_repository_impl.dart';
import 'features/home/domain/home_repository.dart';
import 'features/stories/data/stories_repository_impl.dart';
import 'features/stories/domain/stories_repository.dart';
import 'router/app_router.dart';

/// Composition root: wires Service (ApiClient, SessionStore) -> Repository
/// -> ViewModel via a single [MultiProvider], entirely through `provider`
/// (no static/singleton access anywhere else in the app).
class StoryGeneratorApp extends StatelessWidget {
  const StoryGeneratorApp({
    super.key,
    required this.apiClient,
    required this.sessionStore,
  });

  final ApiClient apiClient;
  final SessionStore sessionStore;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: apiClient),
        Provider<SessionStore>.value(value: sessionStore),
        Provider<AuthRepository>(
          create: (_) => AuthRepositoryImpl(apiClient, sessionStore),
        ),
        Provider<HomeRepository>(create: (_) => HomeRepositoryImpl(apiClient)),
        Provider<StoriesRepository>(
          create: (_) => StoriesRepositoryImpl(apiClient),
        ),
        ChangeNotifierProvider<AuthViewModel>(
          create: (context) =>
              AuthViewModel(context.read<AuthRepository>())..checkSession(),
        ),
        ChangeNotifierProvider<ThemeController>(
          create: (_) => ThemeController(),
        ),
      ],
      child: const _AppRouterHost(),
    );
  }
}

/// Builds the [GoRouter] exactly once (it self-updates via
/// `refreshListenable`), then hands it to [MaterialApp.router].
class _AppRouterHost extends StatefulWidget {
  const _AppRouterHost();

  @override
  State<_AppRouterHost> createState() => _AppRouterHostState();
}

class _AppRouterHostState extends State<_AppRouterHost> {
  late final GoRouter _router = buildAppRouter(context.read<AuthViewModel>());

  // Seeds ThemeController from the session's saved preference the first
  // time it loads, then leaves it alone so later manual toggles stick.
  bool _themeSyncedFromSession = false;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthViewModel>().currentUser;
    final themeController = context.watch<ThemeController>();

    if (!_themeSyncedFromSession && user != null) {
      _themeSyncedFromSession = true;
      final savedMode = user.themePreference == 'dark' ? ThemeMode.dark : ThemeMode.light;
      if (savedMode != themeController.mode) {
        WidgetsBinding.instance.addPostFrameCallback((_) => themeController.setMode(savedMode));
      }
    }

    final themeMode = themeController.mode;
    return MaterialApp.router(
      title: 'Read English Story',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: _router,
    );
  }
}
