import 'package:flutter/material.dart';

import '../viewmodels/create_story_view_model.dart';

/// Lets the user hand-pick words for the story instead of relying on the
/// random sample: search the word bank, tick words as checkboxes, and once
/// [CreateStoryViewModel.wordCount] words are picked the remaining checkboxes
/// disable themselves — only unticking a picked word frees up a slot again.
///
/// The results list gets scroll priority (it's the innermost scrollable
/// under the finger), but once it's exhausted, further drag in the same
/// gesture hands off to [pageScrollController] instead of getting stuck —
/// so one continuous drag can scroll the results then the whole page.
class WordSearchPicker extends StatelessWidget {
  const WordSearchPicker({
    super.key,
    required this.viewModel,
    required this.pageScrollController,
  });

  final CreateStoryViewModel viewModel;
  final ScrollController pageScrollController;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          decoration: InputDecoration(
            hintText: 'ค้นหาคำศัพท์',
            prefixIcon: const Icon(Icons.search),
            border: const OutlineInputBorder(),
            isDense: true,
          ),
          onChanged: viewModel.search,
        ),
        const SizedBox(height: 8),
        Text(
          'เลือกแล้ว ${viewModel.selectedWords.length} / ${viewModel.wordCount} คำ',
          style: theme.textTheme.bodySmall,
        ),
        if (viewModel.selectedWords.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final word in viewModel.selectedWords)
                InputChip(
                  label: Text(word.word),
                  onDeleted: () => viewModel.toggleWordSelection(word),
                ),
            ],
          ),
        ],
        const SizedBox(height: 8),
        if (viewModel.isSearching)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          )
        else if (viewModel.searchQuery.trim().isNotEmpty &&
            viewModel.searchResults.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'ไม่พบคำศัพท์ที่ค้นหา',
              style: theme.textTheme.bodySmall,
            ),
          )
        else
          Container(
            constraints: const BoxConstraints(maxHeight: 260),
            decoration: BoxDecoration(
              border: Border.all(color: theme.colorScheme.outline),
              borderRadius: BorderRadius.circular(8),
            ),
            child: viewModel.searchResults.isEmpty
                ? const SizedBox.shrink()
                : NotificationListener<OverscrollNotification>(
                    onNotification: (notification) {
                      final position = pageScrollController.position;
                      final target = (position.pixels + notification.overscroll)
                          .clamp(position.minScrollExtent, position.maxScrollExtent);
                      pageScrollController.jumpTo(target);
                      return false;
                    },
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const ClampingScrollPhysics(),
                      itemCount: viewModel.searchResults.length,
                      itemBuilder: (context, index) {
                        final word = viewModel.searchResults[index];
                        final isSelected = viewModel.isWordSelected(word);
                        final isSelectable = viewModel.isWordSelectable(word);
                        return CheckboxListTile(
                          dense: true,
                          title: Text(word.word),
                          value: isSelected,
                          onChanged: isSelectable
                              ? (_) => viewModel.toggleWordSelection(word)
                              : null,
                        );
                      },
                    ),
                  ),
          ),
      ],
    );
  }
}
