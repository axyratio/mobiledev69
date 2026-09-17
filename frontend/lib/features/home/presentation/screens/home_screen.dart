import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/theme_controller.dart';
import '../../domain/home_repository.dart';
import '../viewmodels/home_view_model.dart';
import '../widgets/story_feed_card.dart';
import '../../../auth/presentation/viewmodels/auth_view_model.dart';

/// Home (mockup 1b): search + sort chips over a feed of the user's own
/// stories, a "today's words" preview, and a create-story FAB.
///
/// Create/My Stories/Settings are out of scope for this pass — their nav
/// destinations show a "coming soon" snackbar instead of a broken screen.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => HomeViewModel(context.read<HomeRepository>()),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  void _showComingSoon(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<HomeViewModel>();
    final user = context.watch<AuthViewModel>().currentUser;
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: viewModel.load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'AI Story Generator',
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Toggle theme',
                    onPressed: () => context.read<ThemeController>().toggle(),
                    icon: Icon(
                      context.watch<ThemeController>().isDark
                          ? Icons.light_mode_outlined
                          : Icons.dark_mode_outlined,
                    ),
                  ),
                  const SizedBox(width: 4),
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    foregroundColor: theme.colorScheme.onPrimaryContainer,
                    child: Text(
                      _initialFor(user?.name),
                      style: theme.textTheme.labelLarge,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                onChanged: viewModel.setSearchQuery,
                decoration: InputDecoration(
                  hintText: 'ค้นหาชื่อเรื่องหรือคำศัพท์',
                  prefixIcon: const Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _SortChip(
                      label: 'ล่าสุด',
                      selected: viewModel.sortMode == StorySortMode.recent,
                      onTap: () => viewModel.setSortMode(StorySortMode.recent),
                    ),
                    const SizedBox(width: 6),
                    _SortChip(
                      label: 'ชื่อเรื่อง A–Z',
                      selected: viewModel.sortMode == StorySortMode.titleAz,
                      onTap: () => viewModel.setSortMode(StorySortMode.titleAz),
                    ),
                    const SizedBox(width: 6),
                    _SortChip(
                      label: 'คำเยอะสุด',
                      selected: viewModel.sortMode == StorySortMode.mostWords,
                      onTap: () =>
                          viewModel.setSortMode(StorySortMode.mostWords),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _SectionLabel('คำศัพท์ของวันนี้'),
              const SizedBox(height: 8),
              if (viewModel.todayWords.isEmpty && !viewModel.isLoading)
                Text('ยังไม่มีคำศัพท์ให้แสดง', style: theme.textTheme.bodySmall)
              else
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final word in viewModel.todayWords)
                      Chip(
                        label: Text(word),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                      ),
                  ],
                ),
              const SizedBox(height: 20),
              _SectionLabel('เรื่องทั้งหมด ${viewModel.storyCount} เรื่อง'),
              const SizedBox(height: 8),
              _StoryFeed(viewModel: viewModel),
            ],
          ),
        ),
      ),
      floatingActionButton: _CreateStoryFab(
        onPressed: () => context.push('/create'),
      ),
      bottomNavigationBar: _HomeBottomNav(
        onMyStories: () => _showComingSoon(context, comingSoonMessage),
        onSettings: () => _showSettingsSheet(context),
      ),
    );
  }

  void _showSettingsSheet(BuildContext context) {
    final authViewModel = context.read<AuthViewModel>();
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.logout_outlined),
              title: const Text('ออกจากระบบ'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                authViewModel.logout();
              },
            ),
          ],
        ),
      ),
    );
  }

  static String _initialFor(String? name) {
    final trimmed = name?.trim() ?? '';
    return trimmed.isEmpty ? '?' : trimmed.substring(0, 1).toUpperCase();
  }
}

const comingSoonMessage = 'ฟีเจอร์นี้จะพร้อมใช้งานเร็ว ๆ นี้';

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelMedium
          ?.copyWith(letterSpacing: 0.4),
    );
  }
}

class _SortChip extends StatelessWidget {
  const _SortChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      selectedColor: theme.colorScheme.primaryContainer,
      labelStyle: theme.textTheme.labelMedium?.copyWith(
        color: selected ? theme.colorScheme.onPrimaryContainer : null,
      ),
      side: BorderSide(
        color: selected ? theme.colorScheme.primary : theme.colorScheme.outline,
      ),
    );
  }
}

class _StoryFeed extends StatelessWidget {
  const _StoryFeed({required this.viewModel});

  final HomeViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (viewModel.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (viewModel.errorMessage != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            viewModel.errorMessage!,
            style: TextStyle(color: theme.colorScheme.error),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: viewModel.retry,
            child: const Text('ลองอีกครั้ง'),
          ),
        ],
      );
    }

    final stories = viewModel.visibleStories;
    if (stories.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            Icon(
              Icons.lock_outline,
              size: 28,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 8),
            Text(
              viewModel.storyCount == 0
                  ? 'ยังไม่มีเรื่องที่คุณสร้าง\nกดปุ่ม + เพื่อเริ่มสร้างเรื่องแรกของคุณ'
                  : 'ไม่พบเรื่องที่ตรงกับการค้นหา',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        for (final story in stories) ...[
          StoryFeedCard(
            story: story,
            onTap: () => context.push('/stories/${story.id}'),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _CreateStoryFab extends StatelessWidget {
  const _CreateStoryFab({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FloatingActionButton.extended(
      onPressed: onPressed,
      backgroundColor: theme.colorScheme.surface,
      foregroundColor: theme.colorScheme.onPrimaryContainer,
      shape: StadiumBorder(side: BorderSide(color: theme.colorScheme.primary)),
      icon: const Icon(Icons.add),
      label: const Text('สร้างเรื่อง'),
    );
  }
}

class _HomeBottomNav extends StatelessWidget {
  const _HomeBottomNav({required this.onMyStories, required this.onSettings});
  final VoidCallback onMyStories;
  final VoidCallback onSettings;

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
              active: true,
              onTap: () {},
            ),
            _NavItem(
              icon: Icons.menu_book_outlined,
              label: 'เรื่องของฉัน',
              active: false,
              onTap: onMyStories,
            ),
            _NavItem(
              icon: Icons.settings_outlined,
              label: 'ตั้งค่า',
              active: false,
              onTap: onSettings,
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
