import 'story_vocab_word.dart';

/// Full story content for the Detail screen (FR-09), including every target
/// word actually used ([words]) plus other vocabulary-bank words the LLM
/// happened to use ([extraWords]), so the body can be highlighted
/// client-side.
class StoryDetail {
  const StoryDetail({
    required this.id,
    required this.title,
    required this.body,
    required this.titleTh,
    required this.bodyTh,
    required this.words,
    required this.extraWords,
    required this.createdAt,
  });

  final int id;
  final String title;
  final String body;

  /// Thai translation of [title]/[body], generated together with the
  /// English version. Empty for stories generated before this existed.
  final String titleTh;
  final String bodyTh;
  final List<StoryVocabWord> words;
  final List<StoryVocabWord> extraWords;
  final DateTime createdAt;

  bool get hasThaiTranslation => bodyTh.isNotEmpty;
}
