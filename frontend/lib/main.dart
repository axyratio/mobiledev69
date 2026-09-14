import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'features/auth/auth_service.dart';
import 'features/auth/auth_state.dart';
import 'features/auth/login_screen.dart';
import 'features/home/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final authService = await AuthService.create();
  runApp(StoryGeneratorApp(authService: authService));
}

class StoryGeneratorApp extends StatelessWidget {
  const StoryGeneratorApp({super.key, required this.authService});

  final AuthService authService;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthState(authService)..checkSession(),
      child: MaterialApp(
        title: 'AI Story Generator',
        theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
        darkTheme: ThemeData(
          colorSchemeSeed: Colors.indigo,
          brightness: Brightness.dark,
          useMaterial3: true,
        ),
        home: const _RootRouter(),
      ),
    );
  }
}

/// Chooses LoginScreen vs HomeScreen based on the session check result
/// (FR-03). Extracted from MaterialApp so it can `watch` AuthState.
class _RootRouter extends StatelessWidget {
  const _RootRouter();

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthState>();

    switch (authState.status) {
      case AuthStatus.unknown:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      case AuthStatus.authenticated:
        return const HomeScreen();
      case AuthStatus.unauthenticated:
        return LoginScreen(
          authService: authState.authService,
          onLoginSuccess: authState.completeLogin,
        );
    }
  }
}
