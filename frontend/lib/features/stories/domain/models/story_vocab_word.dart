/// A vocabulary word tied to a [StoryDetail] — either one of the target
/// words the story was generated from, or one the LLM happened to use that
/// also exists in the vocabulary bank. Carries the CEFR level (highlight
/// filtering) and the definition shown when a highlighted word is tapped.
class StoryVocabWord {
  const StoryVocabWord({
    required this.word,
    required this.cefrLevel,
    required this.definitionEn,
    required this.definitionTh,
    required this.example,
  });

  final String word;
  final String cefrLevel;
  final String definitionEn;
  final String definitionTh;
  final String example;

  bool get hasDefinition =>
      definitionEn.isNotEmpty || definitionTh.isNotEmpty || example.isNotEmpty;
}
