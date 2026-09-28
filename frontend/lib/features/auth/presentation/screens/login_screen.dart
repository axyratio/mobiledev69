import 'package:flutter/material.dart';

import '../../../../core/auth/oidc_auth.dart';
import '../widgets/auth_scaffold.dart';

/// Sole entry point into the app (FR-01) — every login and sign-up now goes
/// through this backend's own OIDC Authorization Code + PKCE flow in the
/// system browser, which has its own linked login/sign-up pages. There is
/// no in-app email/password form anymore: keeping one here alongside OIDC
/// would just be two ways to do the same thing against the same user
/// database.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AuthScaffold(
      title: 'Welcome back',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Sign in or create an account — the next screen handles both.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => signInWithOidc(context),
            icon: const Icon(Icons.shield_outlined, size: 20),
            label: const Text('Continue'),
          ),
        ],
      ),
    );
  }
}
