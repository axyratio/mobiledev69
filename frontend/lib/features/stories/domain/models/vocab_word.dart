/// A single vocabulary word offered by the server for the create-story flow
/// (FR-05). Pure domain model — no JSON here, that's [VocabWordDto]'s job.
class VocabWord {
  const VocabWord({required this.id, required this.word});

  final int id;
  final String word;
}
