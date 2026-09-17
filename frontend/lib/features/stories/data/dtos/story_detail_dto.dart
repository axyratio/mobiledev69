import '../../domain/models/story_detail.dart';
import '../../domain/models/story_vocab_word.dart';

/// Wire format for a story returned by `POST /api/stories/generate/` and
/// `GET /api/stories/<id>/`.
class StoryDetailDto {
  const StoryDetailDto({
    required this.id,
    required this.title,
    required this.body,
    required this.words,
    required this.extraWords,
    required this.createdAt,
  });

  final int id;
  final String title;
  final String body;
  final List<StoryVocabWord> words;
  final List<StoryVocabWord> extraWords;
  final DateTime createdAt;

  factory StoryDetailDto.fromJson(Map<String, dynamic> json) {
    return StoryDetailDto(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      words: _parseWords(json['words']),
      extraWords: _parseWords(json['extra_words']),
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
    );
  }

  static List<StoryVocabWord> _parseWords(dynamic json) {
    return (json as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>()
        .map(
          (word) => StoryVocabWord(
            word: word['word'] as String? ?? '',
            cefrLevel: word['cefr_level'] as String? ?? 'A1',
            definitionEn: word['definition_en'] as String? ?? '',
            definitionTh: word['definition_th'] as String? ?? '',
            example: word['example'] as String? ?? '',
          ),
        )
        .toList();
  }

  StoryDetail toDomain() {
    return StoryDetail(
      id: id,
      title: title,
      body: body,
      words: words,
      extraWords: extraWords,
      createdAt: createdAt,
    );
  }
}
