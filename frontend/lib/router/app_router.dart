import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/signup_screen.dart';
import '../features/auth/presentation/viewmodels/auth_view_model.dart';
import '../features/home/presentation/screens/home_screen.dart';
import '../features/stories/domain/models/story_detail.dart';
import '../features/stories/presentation/screens/create_story_screen.dart';
import '../features/stories/presentation/screens/story_detail_screen.dart';
import 'auth_guard.dart';

/// Builds the app's [GoRouter]. [authViewModel] drives both the guard
/// (`redirect`) and `refreshListenable`, so a login/logout anywhere in the
/// app re-evaluates routing without any screen calling `context.go`
/// itself.
GoRouter buildAppRouter(AuthViewModel authViewModel) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: authViewModel,
    redirect: (context, state) => authGuard(authViewModel, state),
    routes: [
      GoRoute(path: '/', builder: (context, state) => const _RootScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/create',
        builder: (context, state) => const CreateStoryScreen(),
      ),
      GoRoute(
        path: '/stories/:id',
        builder: (context, state) => StoryDetailScreen(
          storyId: int.parse(state.pathParameters['id']!),
          preloaded: state.extra as StoryDetail?,
        ),
      ),
    ],
  );
}

/// Splash spinner while the initial session check ([AuthStatus.unknown])
/// is pending, otherwise [HomeScreen] — [authGuard] guarantees an
/// unauthenticated session never reaches this route.
class _RootScreen extends StatelessWidget {
  const _RootScreen();

  @override
  Widget build(BuildContext context) {
    final status = context.watch<AuthViewModel>().status;
    if (status == AuthStatus.unknown) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return const HomeScreen();
  }
}
