import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/theme_controller.dart';

/// Shared visual shell for the login/sign-up screens, restyled to the
/// Nocturne design reference: a flat surface (no gradient header), a theme
/// toggle available even while signed out (per the design's guest-state
/// copy: "สลับโหมดมืดได้แม้ยังไม่ล็อกอิน"), and a centered form card.
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
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  if (onBack != null)
                    IconButton(
                      onPressed: onBack,
                      icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                    )
                  else
                    const SizedBox(width: 8),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Toggle theme',
                    onPressed: () => context.read<ThemeController>().toggle(),
                    icon: Icon(
                      context.watch<ThemeController>().isDark
                          ? Icons.light_mode_outlined
                          : Icons.dark_mode_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 4,
                    height: 18,
                    color: theme.colorScheme.primary,
                    margin: const EdgeInsets.only(right: 8),
                  ),
                  Text(
                    'Oxford 3000',
                    style: theme.textTheme.labelMedium?.copyWith(
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 28),
              child,
            ],
          ),
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
    final theme = Theme.of(context);
    return Column(
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(dividerLabel, style: theme.textTheme.bodySmall),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: onGooglePressed,
          icon: const _GoogleBadge(),
          label: const Text('Continue with Google'),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(promptText, style: theme.textTheme.bodyMedium),
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
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
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
