import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/format/thai_datetime.dart';
import '../../../../core/result.dart';
import '../../../auth/presentation/viewmodels/auth_view_model.dart';
import '../../domain/models/story_detail.dart';
import '../../domain/models/story_vocab_word.dart';
import '../../domain/stories_repository.dart';
import '../viewmodels/story_detail_view_model.dart';
import '../widgets/highlighted_story_body.dart';

/// Longest title the rename sheet accepts (mockup 1j) — a UX cap on
/// editing, distinct from the model's storage limit.
const _maxTitleLength = 80;

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
        initialLevel: context.read<AuthViewModel>().currentUser?.cefrLevel ?? 'A1',
        filterByLevel:
            context.read<AuthViewModel>().currentUser?.highlightFilterByLevelEnabled ?? true,
      ),
      child: const _StoryDetailView(),
    );
  }
}

class _StoryDetailView extends StatelessWidget {
  const _StoryDetailView();

  Future<void> _editTitle(BuildContext context, StoryDetailViewModel viewModel) async {
    final story = viewModel.story;
    if (story == null) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _EditTitleSheet(viewModel: viewModel, currentTitle: story.title),
    );
  }

  Future<void> _confirmDelete(BuildContext context, StoryDetailViewModel viewModel) async {
    final story = viewModel.story;
    if (story == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _DeleteStoryDialog(title: story.title),
    );
    if (confirmed != true) return;

    final result = await viewModel.delete();
    if (!context.mounted) return;
    switch (result) {
      case Ok():
        context.pop();
      case Err(message: final message):
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message)));
    }
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
                  if (viewModel.story != null) _LanguageToggle(viewModel: viewModel),
                  IconButton(
                    onPressed: viewModel.story == null
                        ? null
                        : () => _editTitle(context, viewModel),
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: 'แก้ไขชื่อเรื่อง',
                  ),
                  IconButton(
                    onPressed: viewModel.story == null
                        ? null
                        : () => _confirmDelete(context, viewModel),
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

/// Rename bottom sheet (mockup 1j, FR-10, FR-12): a single text field with
/// a live character counter and a "ห้ามเว้นว่าง" hint, styled to match the
/// primary-outlined "บันทึก" action.
class _EditTitleSheet extends StatefulWidget {
  const _EditTitleSheet({required this.viewModel, required this.currentTitle});

  final StoryDetailViewModel viewModel;
  final String currentTitle;

  @override
  State<_EditTitleSheet> createState() => _EditTitleSheetState();
}

class _EditTitleSheetState extends State<_EditTitleSheet> {
  late final _controller = TextEditingController(text: widget.currentTitle);
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isUnchanged => _controller.text.trim() == widget.currentTitle.trim();

  Future<void> _save() async {
    final title = _controller.text.trim();
    if (title.isEmpty || _isUnchanged) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final result = await widget.viewModel.rename(title);
    if (!mounted) return;

    switch (result) {
      case Ok():
        Navigator.of(context).pop();
      case Err(message: final message):
        setState(() {
          _isSaving = false;
          _errorMessage = message;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        4,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('แก้ไขชื่อเรื่อง', style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'แก้ได้เฉพาะเรื่องที่คุณเป็นเจ้าของ',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _controller,
            autofocus: true,
            maxLength: _maxTitleLength,
            enabled: !_isSaving,
            decoration: InputDecoration(
              counterText: '',
              suffixIcon: ValueListenableBuilder<TextEditingValue>(
                valueListenable: _controller,
                builder: (context, value, _) => value.text.isEmpty
                    ? const SizedBox.shrink()
                    : IconButton(
                        icon: const Icon(Icons.cancel, size: 18),
                        onPressed: () => setState(() => _controller.clear()),
                      ),
              ),
            ),
            onChanged: (_) => setState(() => _errorMessage = null),
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _errorMessage ?? 'ห้ามเว้นว่าง',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: _errorMessage != null
                      ? theme.colorScheme.error
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _controller,
                builder: (context, value, _) => Text(
                  '${value.text.length} / $_maxTitleLength',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                  child: const Text('ยกเลิก'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _controller,
                  builder: (context, value, _) {
                    final disabled =
                        _isSaving || value.text.trim().isEmpty || _isUnchanged;
                    return OutlinedButton.icon(
                      onPressed: disabled ? null : _save,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check, size: 18),
                      label: const Text('บันทึก'),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Delete confirmation dialog (mockup 1k, FR-11, NFR-06): a permanent,
/// error-toned warning — no undo once confirmed. Pops `true`/`false`; the
/// caller performs the actual delete call once this closes.
class _DeleteStoryDialog extends StatelessWidget {
  const _DeleteStoryDialog({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      icon: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.error),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.delete_outline, color: theme.colorScheme.error),
      ),
      title: Text('ลบ "$title"?'),
      content: Text(
        'เรื่องและคำศัพท์ที่ผูกกับเรื่องนี้จะถูกลบถาวร ย้อนกลับไม่ได้',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('ยกเลิก'),
        ),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: theme.colorScheme.error,
            side: BorderSide(color: theme.colorScheme.error),
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('ลบเรื่อง'),
        ),
      ],
    );
  }
}

/// Plain paragraph rendering for the Thai translation — no word highlighting
/// or tap, since target-word matching only applies to the English body.
class _PlainStoryBody extends StatelessWidget {
  const _PlainStoryBody({required this.body});

  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseStyle = (theme.textTheme.bodyLarge ?? const TextStyle()).copyWith(
      color: theme.colorScheme.onSurface,
      height: 1.85,
    );
    final paragraphs = body.split(RegExp(r'\n+')).where((p) => p.trim().isNotEmpty);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final paragraph in paragraphs)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Text('      $paragraph', style: baseStyle),
          ),
      ],
    );
  }
}

/// TH/EN switch (mockup 1h extension): swaps the article body — and which
/// language the word-definition sheet leads with — between the generated
/// English story and its Thai translation.
class _LanguageToggle extends StatelessWidget {
  const _LanguageToggle({required this.viewModel});

  final StoryDetailViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final story = viewModel.story;
    final hasThai = story?.hasThaiTranslation ?? false;
    return SegmentedButton<StoryLanguage>(
      segments: const [
        ButtonSegment(value: StoryLanguage.en, label: Text('EN')),
        ButtonSegment(value: StoryLanguage.th, label: Text('TH')),
      ],
      selected: {viewModel.language},
      showSelectedIcon: false,
      onSelectionChanged: !hasThai
          ? null
          : (_) => viewModel.toggleLanguage(),
      style: const ButtonStyle(visualDensity: VisualDensity.compact),
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

    final showThai = viewModel.language == StoryLanguage.th && story.hasThaiTranslation;
    final displayTitle = showThai && story.titleTh.isNotEmpty ? story.titleTh : story.title;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(displayTitle, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            '${formatThaiDateTime(story.createdAt)} · ${story.words.length} คำเป้าหมาย',
            style: theme.textTheme.bodySmall,
          ),
          const Divider(height: 32),
          if (showThai)
            _PlainStoryBody(body: story.bodyTh)
          else
            HighlightedStoryBody(
              body: story.body,
              mainWords: viewModel.highlightedWords,
              extraWords: viewModel.extraHighlightedWords,
              onWordTap: (word) => _showWordDefinition(context, viewModel, word),
            ),
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
                        label: Text(word.word),
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

/// Shows the tapped word's definition in a bottom sheet, defaulting to
/// whichever language the article body is currently shown in. Does nothing
/// if the word can't be found (shouldn't happen — the tapped text always
/// comes from a word the highlighter itself matched).
void _showWordDefinition(BuildContext context, StoryDetailViewModel viewModel, String word) {
  final entry = viewModel.findWord(word);
  if (entry == null) return;
  showModalBottomSheet(
    context: context,
    showDragHandle: true,
    builder: (context) => _WordDefinitionSheet(word: entry, initialLanguage: viewModel.language),
  );
}

/// Word-definition popup (extends FR-09): a TH/EN toggle picks which single
/// definition is shown, instead of always stacking both translations.
class _WordDefinitionSheet extends StatefulWidget {
  const _WordDefinitionSheet({required this.word, required this.initialLanguage});

  final StoryVocabWord word;
  final StoryLanguage initialLanguage;

  @override
  State<_WordDefinitionSheet> createState() => _WordDefinitionSheetState();
}

class _WordDefinitionSheetState extends State<_WordDefinitionSheet> {
  late StoryLanguage _language = widget.initialLanguage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final word = widget.word;
    final showThai = _language == StoryLanguage.th;
    final definition = showThai ? word.definitionTh : word.definitionEn;
    final fallback = showThai ? word.definitionEn : word.definitionTh;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(word.word, style: theme.textTheme.headlineSmall),
                const SizedBox(width: 10),
                Chip(
                  label: Text(word.cefrLevel),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                const Spacer(),
                SegmentedButton<StoryLanguage>(
                  segments: const [
                    ButtonSegment(value: StoryLanguage.en, label: Text('EN')),
                    ButtonSegment(value: StoryLanguage.th, label: Text('TH')),
                  ],
                  selected: {_language},
                  showSelectedIcon: false,
                  onSelectionChanged: (selection) =>
                      setState(() => _language = selection.first),
                  style: const ButtonStyle(visualDensity: VisualDensity.compact),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (!word.hasDefinition)
              Text(
                'ยังไม่มีคำอธิบายสำหรับคำนี้',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else ...[
              // Falls back to the other language rather than showing
              // nothing when only one translation was seeded for this word.
              Text(
                definition.isNotEmpty ? definition : fallback,
                style: theme.textTheme.bodyLarge,
              ),
              if (word.example.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  '"${word.example}"',
                  style: theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
