import 'package:flutter/material.dart';

/// Renders a story body with every target [words] entry highlighted
/// (FR-09), matching on whole words case-insensitively so "Harbour" and
/// "harbour." both count.
class HighlightedStoryBody extends StatelessWidget {
  const HighlightedStoryBody({
    super.key,
    required this.body,
    required this.words,
  });

  final String body;
  final List<String> words;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseStyle = (theme.textTheme.bodyLarge ?? const TextStyle()).copyWith(
      color: theme.colorScheme.onSurface,
      height: 1.85,
    );
    final highlightStyle = baseStyle.copyWith(
      color: theme.colorScheme.onPrimaryContainer,
      fontWeight: FontWeight.w600,
      backgroundColor: theme.colorScheme.primaryContainer,
      decoration: TextDecoration.underline,
      decorationColor: theme.colorScheme.primary,
    );

    final paragraphs = body
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
                children: _highlightedSpans(
                  paragraph,
                  baseStyle,
                  highlightStyle,
                ),
              ),
            ),
          ),
      ],
    );
  }

  List<TextSpan> _highlightedSpans(
    String paragraph,
    TextStyle baseStyle,
    TextStyle highlightStyle,
  ) {
    if (words.isEmpty) return [TextSpan(text: paragraph, style: baseStyle)];

    final pattern = words.map(RegExp.escape).join('|');
    final regex = RegExp('\\b($pattern)\\b', caseSensitive: false);

    final spans = <TextSpan>[];
    var cursor = 0;
    for (final match in regex.allMatches(paragraph)) {
      if (match.start > cursor) {
        spans.add(
          TextSpan(
            text: paragraph.substring(cursor, match.start),
            style: baseStyle,
          ),
        );
      }
      spans.add(
        TextSpan(
          text: paragraph.substring(match.start, match.end),
          style: highlightStyle,
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
