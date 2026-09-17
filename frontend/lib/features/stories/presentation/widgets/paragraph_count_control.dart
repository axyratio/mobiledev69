import 'package:flutter/material.dart';

import '../viewmodels/create_story_view_model.dart';

/// Quick-pick chips for choosing how many paragraphs the story should be
/// split into.
class ParagraphCountControl extends StatelessWidget {
  const ParagraphCountControl({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'จำนวนย่อหน้า ($minStoryParagraphs–$maxStoryParagraphs)',
          style: theme.textTheme.labelMedium,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (var count = minStoryParagraphs;
                count <= maxStoryParagraphs;
                count++)
              ChoiceChip(
                label: Text('$count'),
                selected: value == count,
                onSelected: (_) => onChanged(count),
                showCheckmark: false,
              ),
          ],
        ),
      ],
    );
  }
}
