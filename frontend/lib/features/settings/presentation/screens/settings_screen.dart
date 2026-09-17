import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/cefr/cefr_level.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../auth/presentation/viewmodels/auth_view_model.dart';
import '../../../home/presentation/widgets/app_bottom_nav.dart';

/// Settings (mockup 1n): profile, display (light/dark), the learner's own
/// CEFR level (moved here from the Story Detail dropdown so it lives in one
/// authoritative place), and account actions.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = context.watch<AuthViewModel>().currentUser;
    final themeController = context.watch<ThemeController>();

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Text('ตั้งค่า', style: theme.textTheme.titleLarge),
            ),
            _ProfileRow(
              name: user?.name,
              email: user?.email,
              oidcProvider: user?.oidcProvider,
            ),
            _Section(
              label: 'การแสดงผล',
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _SegmentedControl<ThemeMode>(
                  value: themeController.mode,
                  segments: const {ThemeMode.light: 'สว่าง', ThemeMode.dark: 'มืด'},
                  onChanged: themeController.setMode,
                ),
              ),
            ),
            _Section(
              label: 'ระดับของฉัน',
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SegmentedControl<String>(
                      value: user?.cefrLevel ?? 'A1',
                      segments: {for (final level in cefrLevels) level: level},
                      onChanged: (level) =>
                          context.read<AuthViewModel>().updateCefrLevel(level),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'ใช้กำหนดว่าคำศัพท์ระดับไหนจะถูก highlight ในหน้ารายละเอียดเรื่อง '
                      'คำที่ง่ายกว่าระดับนี้จะไม่ถูก highlight',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            _Section(
              label: 'บัญชี',
              child: _SettingsRow(
                icon: Icons.logout_outlined,
                label: 'ออกจากระบบ',
                labelColor: theme.colorScheme.error,
                onTap: () => context.read<AuthViewModel>().logout(),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(active: AppTab.settings),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({required this.name, required this.email, required this.oidcProvider});

  final String? name;
  final String? email;
  final String? oidcProvider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trimmedName = name?.trim() ?? '';
    final initial = trimmedName.isEmpty ? '?' : trimmedName.substring(0, 1).toUpperCase();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outline),
          bottom: BorderSide(color: theme.colorScheme.outline),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: theme.colorScheme.primaryContainer,
            foregroundColor: theme.colorScheme.onPrimaryContainer,
            child: Text(initial, style: theme.textTheme.titleMedium),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(trimmedName, style: theme.textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(email ?? '', style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          if (oidcProvider != null && oidcProvider!.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: theme.colorScheme.outline),
              ),
              child: Text(
                _capitalize(oidcProvider!),
                style: theme.textTheme.labelSmall,
              ),
            ),
        ],
      ),
    );
  }

  static String _capitalize(String value) =>
      value.isEmpty ? value : value[0].toUpperCase() + value.substring(1);
}

class _Section extends StatelessWidget {
  const _Section({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 22, 16, 8),
          child: Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(letterSpacing: 0.6),
          ),
        ),
        child,
      ],
    );
  }
}

class _SegmentedControl<T> extends StatelessWidget {
  const _SegmentedControl({
    required this.value,
    required this.segments,
    required this.onChanged,
  });

  final T value;
  final Map<T, String> segments;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entries = segments.entries.toList();
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outline),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          for (var i = 0; i < entries.length; i++)
            Expanded(
              child: InkWell(
                onTap: () => onChanged(entries[i].key),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: entries[i].key == value
                        ? theme.colorScheme.primaryContainer
                        : null,
                    border: i == 0
                        ? null
                        : Border(left: BorderSide(color: theme.colorScheme.outline)),
                  ),
                  child: Text(
                    entries[i].value,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: entries[i].key == value
                          ? theme.colorScheme.onPrimaryContainer
                          : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      fontWeight: entries[i].key == value ? FontWeight.w600 : null,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.labelColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? labelColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 12),
            Text(
              label,
              style: theme.textTheme.bodyLarge?.copyWith(color: labelColor),
            ),
          ],
        ),
      ),
    );
  }
}
