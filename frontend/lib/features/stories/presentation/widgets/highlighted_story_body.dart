import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Renders a story body with two kinds of underlined + lightly highlighted
/// words (FR-09 plus the bonus vocabulary extra): [mainWords] (the words the
/// story was generated from) in aqua, [extraWords] (other vocabulary-bank
/// words the LLM happened to use, A2+) in light green. Matches on whole
/// words, case-insensitively. Tapping any highlighted word calls
/// [onWordTap] with the word as it appears in the text, so the caller can
/// show its definition.
class HighlightedStoryBody extends StatefulWidget {
  static const _mainColor = Color(0xFF00BCD4); // aqua
  static const _extraColor = Color(0xFF8BC34A); // light green

  const HighlightedStoryBody({
    super.key,
    required this.body,
    required this.mainWords,
    required this.extraWords,
    this.onWordTap,
  });

  final String body;
  final List<String> mainWords;
  final List<String> extraWords;
  final ValueChanged<String>? onWordTap;

  @override
  State<HighlightedStoryBody> createState() => _HighlightedStoryBodyState();
}

class _HighlightedStoryBodyState extends State<HighlightedStoryBody> {
  final List<TapGestureRecognizer> _recognizers = [];

  void _disposeRecognizers() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _disposeRecognizers();

    final theme = Theme.of(context);
    final baseStyle = (theme.textTheme.bodyLarge ?? const TextStyle()).copyWith(
      color: theme.colorScheme.onSurface,
      height: 1.85,
    );
    final mainStyle = baseStyle.copyWith(
      backgroundColor: HighlightedStoryBody._mainColor.withValues(alpha: 0.18),
      decoration: TextDecoration.underline,
      decorationColor: HighlightedStoryBody._mainColor,
      decorationThickness: 2,
    );
    final extraStyle = baseStyle.copyWith(
      backgroundColor: HighlightedStoryBody._extraColor.withValues(alpha: 0.18),
      decoration: TextDecoration.underline,
      decorationColor: HighlightedStoryBody._extraColor,
      decorationThickness: 2,
    );

    final paragraphs = widget.body
        .split(RegExp(r'\n+'))
        .where((p) => p.trim().isNotEmpty)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final paragraph in paragraphs)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: RichText(
              text: TextSpan(
                children: [
                  // Fixed-width first-line indent (a "tab") so each
                  // paragraph reads distinctly, matching mockup 1h.
                  const WidgetSpan(child: SizedBox(width: 28)),
                  ..._highlightedSpans(paragraph, baseStyle, mainStyle, extraStyle),
                ],
              ),
            ),
          ),
      ],
    );
  }

  List<TextSpan> _highlightedSpans(
    String paragraph,
    TextStyle baseStyle,
    TextStyle mainStyle,
    TextStyle extraStyle,
  ) {
    final allWords = {...widget.mainWords, ...widget.extraWords};
    if (allWords.isEmpty) return [TextSpan(text: paragraph, style: baseStyle)];

    final extraLower = widget.extraWords.map((w) => w.toLowerCase()).toSet();
    // Longest first so e.g. "give up" (if ever multi-word) can't be shadowed
    // by a shorter word matching inside it.
    final ordered = allWords.toList()..sort((a, b) => b.length.compareTo(a.length));
    final pattern = ordered.map(RegExp.escape).join('|');
    final regex = RegExp('\\b($pattern)\\b', caseSensitive: false);

    final spans = <TextSpan>[];
    var cursor = 0;
    for (final match in regex.allMatches(paragraph)) {
      if (match.start > cursor) {
        spans.add(
          TextSpan(text: paragraph.substring(cursor, match.start), style: baseStyle),
        );
      }
      final matchedText = paragraph.substring(match.start, match.end);
      final isExtra = extraLower.contains(matchedText.toLowerCase());
      final onWordTap = widget.onWordTap;
      final recognizer = onWordTap == null
          ? null
          : (TapGestureRecognizer()..onTap = () => onWordTap(matchedText));
      if (recognizer != null) _recognizers.add(recognizer);
      spans.add(
        TextSpan(
          text: matchedText,
          style: isExtra ? extraStyle : mainStyle,
          recognizer: recognizer,
        ),
      );
      cursor = match.end;
    }
    if (cursor < paragraph.length) {
      spans.add(TextSpan(text: paragraph.substring(cursor), style: baseStyle));
    }
    return spans;
  }
}
