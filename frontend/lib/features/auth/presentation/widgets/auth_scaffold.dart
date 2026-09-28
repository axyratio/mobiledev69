import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/theme_controller.dart';

/// Visual shell for [LoginScreen], restyled to the Nocturne design
/// reference: a flat surface (no gradient header), a theme toggle available
/// even while signed out (per the design's guest-state copy:
/// "สลับโหมดมืดได้แม้ยังไม่ล็อกอิน"), and a centered card.
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
