import 'package:flutter/material.dart';

/// Shared visual shell for the login/sign-up screens: a gradient header
/// (loosely matching the provided design reference) above a rounded white
/// card that holds the form.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.child,
    this.onBack,
  });

  final String title;
  final Widget child;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.primary,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 96,
              child: Align(
                alignment: Alignment.centerLeft,
                child: onBack == null
                    ? null
                    : TextButton.icon(
                        onPressed: onBack,
                        style: TextButton.styleFrom(foregroundColor: Colors.white),
                        icon: const Icon(Icons.arrow_back_ios_new, size: 16),
                        label: const Text('Back'),
                      ),
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                      ),
                      const SizedBox(height: 24),
                      child,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Sign up with" / "Sign in with" divider + the Google button, and the
/// switch-mode link at the bottom. Shared between login and sign-up.
class AuthFooter extends StatelessWidget {
  const AuthFooter({
    super.key,
    required this.dividerLabel,
    required this.onGooglePressed,
    required this.promptText,
    required this.actionText,
    required this.onActionPressed,
  });

  final String dividerLabel;
  final VoidCallback onGooglePressed;
  final String promptText;
  final String actionText;
  final VoidCallback onActionPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(dividerLabel, style: Theme.of(context).textTheme.bodySmall),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: onGooglePressed,
          icon: const _GoogleBadge(),
          label: const Text('Continue with Google'),
          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(promptText, style: Theme.of(context).textTheme.bodyMedium),
            TextButton(onPressed: onActionPressed, child: Text(actionText)),
          ],
        ),
      ],
    );
  }
}

class _GoogleBadge extends StatelessWidget {
  const _GoogleBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      alignment: Alignment.center,
      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      child: const Text(
        'G',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Color(0xFF4285F4),
          height: 1,
        ),
      ),
    );
  }
}
