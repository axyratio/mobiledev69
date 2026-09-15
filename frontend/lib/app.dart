import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/api/api_client.dart';
import 'core/auth/session_store.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/auth_repository_impl.dart';
import 'features/auth/domain/auth_repository.dart';
import 'features/auth/presentation/viewmodels/auth_view_model.dart';
import 'router/app_router.dart';

/// Composition root: wires Service (ApiClient, SessionStore) -> Repository
/// -> ViewModel via a single [MultiProvider], entirely through `provider`
/// (no static/singleton access anywhere else in the app).
class StoryGeneratorApp extends StatelessWidget {
  const StoryGeneratorApp({super.key, required this.apiClient, required this.sessionStore});

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
        ChangeNotifierProvider<AuthViewModel>(
          create: (context) => AuthViewModel(context.read<AuthRepository>())..checkSession(),
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

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'AI Story Generator',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routerConfig: _router,
    );
  }
}
