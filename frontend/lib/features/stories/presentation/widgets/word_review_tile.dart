import 'package:flutter/material.dart';

import '../../domain/models/vocab_word.dart';

/// One row on the "words we picked" review step (FR-05), with a per-word
/// re-roll action.
class WordReviewTile extends StatelessWidget {
  const WordReviewTile({
    super.key,
    required this.index,
    required this.word,
    required this.onReroll,
    this.isBusy = false,
  });

  final int index;
  final VocabWord word;
  final VoidCallback onReroll;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 18,
            child: Text('$index', style: theme.textTheme.labelMedium),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(word.word, style: theme.textTheme.titleMedium)),
          IconButton(
            onPressed: isBusy ? null : onReroll,
            icon: const Icon(Icons.refresh, size: 18),
            tooltip: 'สุ่มคำนี้ใหม่',
          ),
        ],
      ),
    );
  }
}
