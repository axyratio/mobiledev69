import '../../domain/models/story_detail.dart';

/// Wire format for a story returned by `POST /api/stories/generate/` and
/// `GET /api/stories/<id>/`.
class StoryDetailDto {
  const StoryDetailDto({
    required this.id,
    required this.title,
    required this.body,
    required this.words,
    required this.createdAt,
  });

  final int id;
  final String title;
  final String body;
  final List<String> words;
  final DateTime createdAt;

  factory StoryDetailDto.fromJson(Map<String, dynamic> json) {
    return StoryDetailDto(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      words: (json['words'] as List<dynamic>? ?? const []).cast<String>(),
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
    );
  }

  StoryDetail toDomain() {
    return StoryDetail(
      id: id,
      title: title,
      body: body,
      words: words,
      createdAt: createdAt,
    );
  }
}
