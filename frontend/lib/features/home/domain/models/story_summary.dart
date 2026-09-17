/// Domain model for a story row in the Home feed (SSOT for the Home
/// feature). Pure — no JSON parsing here, that's [StoryDto]'s job.
class StorySummary {
  const StorySummary({
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
}
