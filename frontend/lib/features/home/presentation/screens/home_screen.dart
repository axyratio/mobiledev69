import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/theme_controller.dart';
import '../../../auth/presentation/viewmodels/auth_view_model.dart';
import '../../domain/home_repository.dart';
import '../viewmodels/home_view_model.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/story_feed_card.dart';

/// Home (mockup 1a): a create-story hero card as the main event, quick
/// stats, today's word sample, and a small preview of recent stories.
/// The full searchable/sortable list lives on My Stories instead.
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

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<HomeViewModel>();
    final user = context.watch<AuthViewModel>().currentUser;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: viewModel.load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              _HeaderRow(name: user?.name),
              const SizedBox(height: 10),
              _Greeting(name: user?.name),
              const SizedBox(height: 18),
              const _CreateStoryHero(),
              const SizedBox(height: 14),
              _StatsRow(viewModel: viewModel),
              const SizedBox(height: 22),
              _TodayWordsSection(viewModel: viewModel),
              const SizedBox(height: 22),
              _RecentStoriesSection(viewModel: viewModel),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNav(active: AppTab.home),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({required this.name});
  final String? name;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Text('AI Story Generator', style: theme.textTheme.titleMedium),
        ),
        _IconSquareButton(
          tooltip: 'Toggle theme',
          onPressed: () => context.read<ThemeController>().toggle(),
          icon: context.watch<ThemeController>().isDark
              ? Icons.light_mode_outlined
              : Icons.dark_mode_outlined,
        ),
        const SizedBox(width: 6),
        CircleAvatar(
          radius: 18,
          backgroundColor: theme.colorScheme.primaryContainer,
          foregroundColor: theme.colorScheme.onPrimaryContainer,
          child: Text(_initialFor(name), style: theme.textTheme.labelLarge),
        ),
      ],
    );
  }

  static String _initialFor(String? name) {
    final trimmed = name?.trim() ?? '';
    return trimmed.isEmpty ? '?' : trimmed.substring(0, 1).toUpperCase();
  }
}

class _IconSquareButton extends StatelessWidget {
  const _IconSquareButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.colorScheme.outline),
          ),
          child: Icon(icon, size: 18, color: theme.colorScheme.onSurface),
        ),
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.name});
  final String? name;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('สวัสดี ${name ?? ''}'.trim(), style: theme.textTheme.bodyMedium),
        const SizedBox(height: 2),
        Text('วันนี้อยากได้เรื่องแบบไหน', style: theme.textTheme.headlineSmall),
      ],
    );
  }
}

class _CreateStoryHero extends StatelessWidget {
  const _CreateStoryHero();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outline),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 18, height: 2, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'OXFORD 3000',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text('สร้างเรื่องใหม่', style: theme.textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            'เลือกจำนวนคำ 3–15 คำ ระบบสุ่มคำให้ แล้ว AI แต่งเป็นเรื่องสั้น',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => context.push('/create'),
              icon: const Icon(Icons.auto_awesome, size: 18),
              label: const Text('เริ่มสร้างเรื่อง'),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.viewModel});
  final HomeViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatBox(value: '${viewModel.storyCount}', label: 'เรื่องของฉัน'),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatBox(
            value: '${viewModel.wordsUsedCount}',
            label: 'คำที่ใช้ไปแล้ว',
          ),
        ),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: theme.textTheme.titleLarge),
          const SizedBox(height: 5),
          Text(label, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(
        context,
      ).textTheme.labelMedium?.copyWith(letterSpacing: 0.4),
    );
  }
}

class _TodayWordsSection extends StatelessWidget {
  const _TodayWordsSection({required this.viewModel});
  final HomeViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('คำศัพท์ของวันนี้'),
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
      ],
    );
  }
}

class _RecentStoriesSection extends StatelessWidget {
  const _RecentStoriesSection({required this.viewModel});
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const _SectionLabel('เรื่องล่าสุด'),
            if (viewModel.storyCount > 0)
              InkWell(
                onTap: () => context.go('/my-stories'),
                child: Text(
                  'ดูทั้งหมด',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (viewModel.storyCount == 0)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'ยังไม่มีเรื่องที่คุณสร้าง\nกดปุ่มด้านบนเพื่อเริ่มสร้างเรื่องแรกของคุณ',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
          )
        else
          for (final story in viewModel.recentStories) ...[
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
