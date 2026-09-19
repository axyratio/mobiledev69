import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../domain/home_repository.dart';
import '../viewmodels/my_stories_view_model.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/story_feed_card.dart';

/// My Stories: search + sort chips (FR-19, FR-20) over the full feed of the
/// user's own stories — the list Home's "ดูทั้งหมด" link and bottom nav tab
/// point to.
class MyStoriesScreen extends StatelessWidget {
  const MyStoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyStoriesViewModel(context.read<HomeRepository>()),
      child: const _MyStoriesView(),
    );
  }
}

class _MyStoriesView extends StatelessWidget {
  const _MyStoriesView();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<MyStoriesViewModel>();
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: viewModel.load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              Text('เรื่องของฉัน', style: theme.textTheme.titleMedium),
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
              Text(
                'เรื่องทั้งหมด ${viewModel.storyCount} เรื่อง',
                style: theme.textTheme.labelMedium?.copyWith(letterSpacing: 0.4),
              ),
              const SizedBox(height: 8),
              _StoryFeed(viewModel: viewModel),
            ],
          ),
        ),
      ),
      floatingActionButton: const _CreateStoryFab(),
      bottomNavigationBar: const AppBottomNav(active: AppTab.myStories),
    );
  }
}

class _CreateStoryFab extends StatelessWidget {
  const _CreateStoryFab();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FloatingActionButton.extended(
      onPressed: () => context.push('/create'),
      backgroundColor: theme.colorScheme.surface,
      foregroundColor: theme.colorScheme.onPrimaryContainer,
      shape: StadiumBorder(side: BorderSide(color: theme.colorScheme.primary)),
      icon: const Icon(Icons.add),
      label: const Text('สร้างเรื่อง'),
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

  final MyStoriesViewModel viewModel;

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
            onTap: () async {
              await context.push('/stories/${story.id}');
              if (context.mounted) viewModel.load();
            },
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}
