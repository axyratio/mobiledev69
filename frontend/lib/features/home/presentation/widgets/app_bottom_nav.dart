import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// The three top-level destinations every main screen's bottom bar shares.
enum AppTab { home, myStories, settings }

/// Bottom navigation shared by Home and My Stories (mockups 1a/1b) — tapping
/// a different tab swaps the whole screen (`context.go`) rather than
/// stacking, since these are sibling destinations, not a drill-down.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key, required this.active});

  final AppTab active;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(top: BorderSide(color: theme.colorScheme.outline)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            _NavItem(
              icon: Icons.home_outlined,
              label: 'หน้าแรก',
              active: active == AppTab.home,
              onTap: () {
                if (active != AppTab.home) context.go('/');
              },
            ),
            _NavItem(
              icon: Icons.menu_book_outlined,
              label: 'เรื่องของฉัน',
              active: active == AppTab.myStories,
              onTap: () {
                if (active != AppTab.myStories) context.go('/my-stories');
              },
            ),
            _NavItem(
              icon: Icons.settings_outlined,
              label: 'ตั้งค่า',
              active: active == AppTab.settings,
              onTap: () {
                if (active != AppTab.settings) context.go('/settings');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = active
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onSurface.withValues(alpha: 0.6);
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(height: 3),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
