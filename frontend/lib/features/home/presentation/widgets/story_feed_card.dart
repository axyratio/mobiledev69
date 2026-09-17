import 'package:flutter/material.dart';

import '../../../../core/format/relative_time.dart';
import '../../domain/models/story_summary.dart';

/// A single row in the Home feed (mockup 1b): title, an optional snippet,
/// up to [maxWordChips] of the words actually used with a "+N" overflow,
/// and a relative timestamp. Reusable later by the My Stories list.
class StoryFeedCard extends StatelessWidget {
  const StoryFeedCard({
    super.key,
    required this.story,
    this.maxWordChips = 3,
    this.onTap,
  });

  final StorySummary story;
  final int maxWordChips;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shownWords = story.words.take(maxWordChips).toList();
    final overflowCount = story.words.length - shownWords.length;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(story.title, style: theme.textTheme.titleSmall),
              if (story.snippet.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  story.snippet,
                  style: theme.textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 9),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final word in shownWords)
                    Text(
                      word,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        decoration: TextDecoration.underline,
                        decorationColor: theme.colorScheme.primary,
                      ),
                    ),
                  Text(
                    overflowCount > 0
                        ? '+$overflowCount · ${formatRelativeTimeThai(story.createdAt)}'
                        : formatRelativeTimeThai(story.createdAt),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
