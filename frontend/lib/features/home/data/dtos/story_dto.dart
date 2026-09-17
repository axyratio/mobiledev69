import '../../domain/models/story_summary.dart';

/// Wire format for a story row returned by `GET /api/stories/`. Confined to
/// the data layer — [toDomain] is the only way out.
class StoryDto {
  const StoryDto({
    required this.id,
    required this.title,
    required this.snippet,
    required this.words,
    required this.createdAt,
  });

  final int id;
  final String title;
  final String snippet;
  final List<String> words;
  final DateTime createdAt;

  factory StoryDto.fromJson(Map<String, dynamic> json) {
    return StoryDto(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      snippet: json['snippet'] as String? ?? '',
      words: (json['words'] as List<dynamic>? ?? const []).cast<String>(),
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
    );
  }

  StorySummary toDomain() {
    return StorySummary(
      id: id,
      title: title,
      snippet: snippet,
      words: words,
      createdAt: createdAt,
    );
  }
}
