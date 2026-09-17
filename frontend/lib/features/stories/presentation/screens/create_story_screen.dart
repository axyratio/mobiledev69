import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../domain/stories_repository.dart';
import '../viewmodels/create_story_view_model.dart';
import '../widgets/paragraph_count_control.dart';
import '../widgets/word_count_control.dart';
import '../widgets/word_review_tile.dart';
import '../widgets/word_search_picker.dart';

/// The create-story wizard (mockups 1e, 1f, 1g, 1m): pick a word count,
/// review the random words, watch the LLM write the story, and — on
/// failure — retry without losing the picked words (FR-04 through FR-07,
/// FR-13, NFR-01).
class CreateStoryScreen extends StatelessWidget {
  const CreateStoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) =>
          CreateStoryViewModel(context.read<StoriesRepository>()),
      child: const _CreateStoryView(),
    );
  }
}

class _CreateStoryView extends StatefulWidget {
  const _CreateStoryView();

  @override
  State<_CreateStoryView> createState() => _CreateStoryViewState();
}

class _CreateStoryViewState extends State<_CreateStoryView> {
  bool _navigatedToStory = false;

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<CreateStoryViewModel>();

    if (viewModel.createdStory != null && !_navigatedToStory) {
      _navigatedToStory = true;
      final story = viewModel.createdStory!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.pushReplacement('/stories/${story.id}', extra: story);
      });
    }

    // A fetch/re-roll failure (as opposed to a generation failure, which
    // gets its own full-screen state below) surfaces as a snackbar (FR-14).
    if (viewModel.errorMessage != null &&
        viewModel.step != CreateStoryStep.error) {
      final message = viewModel.errorMessage!;
      final retry = viewModel.step == CreateStoryStep.pickCount
          ? viewModel.confirmCount
          : viewModel.rerollAll;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(message),
              action: SnackBarAction(label: 'ลองใหม่', onPressed: retry),
            ),
          );
        viewModel.clearError();
      });
    }

    return Scaffold(
      body: SafeArea(
        child: switch (viewModel.step) {
          CreateStoryStep.pickCount => _PickCountStep(viewModel: viewModel),
          CreateStoryStep.reviewWords => _ReviewWordsStep(viewModel: viewModel),
          CreateStoryStep.generating => _GeneratingStep(viewModel: viewModel),
          CreateStoryStep.error => _ErrorStep(viewModel: viewModel),
        },
      ),
    );
  }
}

class _WizardHeader extends StatelessWidget {
  const _WizardHeader({required this.title, this.stepLabel, this.progress});

  final String title;
  final String? stepLabel;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
          child: Row(
            children: [
              IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back),
              ),
              Expanded(child: Text(title, style: theme.textTheme.titleMedium)),
              if (stepLabel != null)
                Text(
                  stepLabel!,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontFamily: 'monospace',
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
        if (progress != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Row(
              children: [
                _ProgressSegment(filled: true),
                const SizedBox(width: 6),
                _ProgressSegment(filled: progress! >= 1),
              ],
            ),
          ),
      ],
    );
  }
}

class _ProgressSegment extends StatelessWidget {
  const _ProgressSegment({required this.filled});
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        height: 3,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(2),
          color: filled ? theme.colorScheme.primary : theme.colorScheme.outline,
        ),
      ),
    );
  }
}

class _PickCountStep extends StatelessWidget {
  const _PickCountStep({required this.viewModel});
  final CreateStoryViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _WizardHeader(
          title: 'สร้างเรื่องใหม่',
          stepLabel: '1 / 2',
          progress: 0,
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ใช้คำศัพท์กี่คำ', style: theme.textTheme.titleLarge),
                const SizedBox(height: 5),
                Text(
                  'ยิ่งคำเยอะ เรื่องยิ่งยาวและท้าทายขึ้น',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),
                WordCountControl(
                  value: viewModel.wordCount,
                  isValid: viewModel.isCountValid,
                  onChanged: viewModel.setWordCount,
                ),
                const SizedBox(height: 18),
                SegmentedButton<WordSelectionMode>(
                  segments: const [
                    ButtonSegment(
                      value: WordSelectionMode.random,
                      label: Text('สุ่มคำศัพท์'),
                      icon: Icon(Icons.shuffle),
                    ),
                    ButtonSegment(
                      value: WordSelectionMode.manual,
                      label: Text('เลือกคำเอง'),
                      icon: Icon(Icons.checklist),
                    ),
                  ],
                  selected: {viewModel.wordSelectionMode},
                  onSelectionChanged: (selection) =>
                      viewModel.setWordSelectionMode(selection.first),
                ),
                if (viewModel.wordSelectionMode == WordSelectionMode.manual) ...[
                  const SizedBox(height: 16),
                  WordSearchPicker(viewModel: viewModel),
                ],
                const SizedBox(height: 22),
                ParagraphCountControl(
                  value: viewModel.paragraphCount,
                  onChanged: viewModel.setParagraphCount,
                ),
                const SizedBox(height: 22),
                Text(
                  'แนวเรื่อง (ไม่บังคับ)',
                  style: theme.textTheme.labelMedium,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final option in createStoryGenres)
                      ChoiceChip(
                        label: Text(option),
                        selected: viewModel.genre == option,
                        onSelected: (_) => viewModel.selectGenre(option),
                        showCheckmark: false,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
          child: Column(
            children: [
              FilledButton.icon(
                onPressed: viewModel.canConfirmPick && !viewModel.isBusy
                    ? viewModel.confirmCount
                    : null,
                icon: viewModel.isBusy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        viewModel.wordSelectionMode == WordSelectionMode.manual
                            ? Icons.check
                            : Icons.shuffle,
                      ),
                label: Text(
                  viewModel.wordSelectionMode == WordSelectionMode.manual
                      ? 'ยืนยันคำที่เลือก'
                      : 'สุ่มคำศัพท์',
                ),
              ),
              if (!viewModel.canConfirmPick) ...[
                const SizedBox(height: 6),
                Text(
                  viewModel.wordSelectionMode == WordSelectionMode.manual
                      ? 'เลือกคำให้ครบ ${viewModel.wordCount} คำก่อน'
                      : 'ปุ่มจะใช้ได้เมื่อจำนวนคำถูกต้อง',
                  style: theme.textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ReviewWordsStep extends StatelessWidget {
  const _ReviewWordsStep({required this.viewModel});
  final CreateStoryViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _WizardHeader(title: 'คำที่สุ่มได้', stepLabel: '2 / 2', progress: 1),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'คำศัพท์ ${viewModel.words.length} คำสำหรับเรื่องนี้',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 5),
                Text(
                  'ตรวจดูก่อนยืนยัน — สุ่มใหม่ได้ทั้งชุดหรือเฉพาะคำ',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                for (var i = 0; i < viewModel.words.length; i++) ...[
                  WordReviewTile(
                    index: i + 1,
                    word: viewModel.words[i],
                    isBusy: viewModel.isBusy,
                    onReroll: () => viewModel.rerollWordAt(i),
                  ),
                  if (i != viewModel.words.length - 1)
                    const SizedBox(height: 8),
                ],
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
          child: Column(
            children: [
              FilledButton.icon(
                onPressed: viewModel.isBusy ? null : viewModel.generate,
                icon: const Icon(Icons.auto_awesome),
                label: const Text('ให้ AI แต่งเรื่อง'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: viewModel.isBusy ? null : viewModel.rerollAll,
                child: const Text('สุ่มใหม่ทั้งชุด'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GeneratingStep extends StatelessWidget {
  const _GeneratingStep({required this.viewModel});
  final CreateStoryViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        _WizardHeader(title: 'กำลังแต่งเรื่อง'),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 62,
                  height: 62,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
                const SizedBox(height: 24),
                Text(
                  'AI กำลังแต่งเรื่องจาก ${viewModel.words.length} คำ',
                  style: theme.textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'ปกติใช้เวลา 5–10 วินาที อย่าเพิ่งปิดหน้านี้',
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final word in viewModel.words)
                      Opacity(
                        opacity: 0.55,
                        child: Chip(label: Text(word.word)),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: OutlinedButton(
            onPressed: viewModel.backToCount,
            child: const Text('ยกเลิก'),
          ),
        ),
      ],
    );
  }
}

class _ErrorStep extends StatelessWidget {
  const _ErrorStep({required this.viewModel});
  final CreateStoryViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        _WizardHeader(title: 'สร้างเรื่องใหม่'),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.transparent,
                  child: Icon(
                    Icons.warning_amber_rounded,
                    size: 28,
                    color: theme.colorScheme.error,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'เชื่อมต่อ AI ไม่สำเร็จ',
                  style: theme.textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'ระบบแต่งเรื่องไม่ตอบกลับภายในเวลาที่กำหนด คำศัพท์ทั้ง ${viewModel.words.length} คำยังถูกเก็บไว้ให้',
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final word in viewModel.words)
                      Opacity(
                        opacity: 0.7,
                        child: Chip(label: Text(word.word)),
                      ),
                  ],
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: viewModel.retryGenerate,
                    icon: const Icon(Icons.refresh),
                    label: const Text('ลองอีกครั้ง'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: viewModel.backToCount,
                    child: const Text('กลับไปแก้จำนวนคำ'),
                  ),
                ),
                if (viewModel.errorMessage != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    viewModel.errorMessage!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
