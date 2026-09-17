/// Full story content for the Detail screen (FR-09), including every target
/// word actually used so the body can be highlighted client-side.
class StoryDetail {
  const StoryDetail({
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
}
