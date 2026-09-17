import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/format/thai_datetime.dart';
import '../../domain/models/story_detail.dart';
import '../../domain/stories_repository.dart';
import '../viewmodels/story_detail_view_model.dart';
import '../widgets/highlighted_story_body.dart';

/// Full story view (mockup 1h): title, target-word highlights in the body
/// (FR-09), and the list of words actually used.
class StoryDetailScreen extends StatelessWidget {
  const StoryDetailScreen({super.key, required this.storyId, this.preloaded});

  final int storyId;
  final StoryDetail? preloaded;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => StoryDetailViewModel(
        context.read<StoriesRepository>(),
        storyId: storyId,
        preloaded: preloaded,
      ),
      child: const _StoryDetailView(),
    );
  }
}

class _StoryDetailView extends StatelessWidget {
  const _StoryDetailView();

  static const _comingSoonMessage = 'ฟีเจอร์นี้จะพร้อมใช้งานเร็ว ๆ นี้';

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text(_comingSoonMessage)));
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<StoryDetailViewModel>();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => _showComingSoon(context),
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: 'แก้ไขชื่อเรื่อง',
                  ),
                  IconButton(
                    onPressed: () => _showComingSoon(context),
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'ลบเรื่อง',
                  ),
                ],
              ),
            ),
            Expanded(child: _StoryDetailBody(viewModel: viewModel)),
          ],
        ),
      ),
    );
  }
}

class _StoryDetailBody extends StatelessWidget {
  const _StoryDetailBody({required this.viewModel});
  final StoryDetailViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final story = viewModel.story;
    if (viewModel.errorMessage != null || story == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                viewModel.errorMessage ?? 'ไม่พบเรื่องนี้',
                style: TextStyle(color: theme.colorScheme.error),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: viewModel.retry,
                child: const Text('ลองอีกครั้ง'),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(story.title, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            '${formatThaiDateTime(story.createdAt)} · ${story.words.length} คำเป้าหมาย',
            style: theme.textTheme.bodySmall,
          ),
          const Divider(height: 32),
          HighlightedStoryBody(body: story.body, words: story.words),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.colorScheme.outline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'คำเป้าหมายที่ใช้จริง',
                      style: theme.textTheme.labelMedium,
                    ),
                    Text(
                      '${story.words.length} คำ',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final word in story.words)
                      Chip(
                        label: Text(word),
                        backgroundColor: theme.colorScheme.primaryContainer,
                        labelStyle: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                        side: BorderSide.none,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
