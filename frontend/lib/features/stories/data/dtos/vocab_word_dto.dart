import '../../domain/models/vocab_word.dart';

/// Wire format for a word returned by `POST /api/words/random/`.
class VocabWordDto {
  const VocabWordDto({required this.id, required this.word});

  final int id;
  final String word;

  factory VocabWordDto.fromJson(Map<String, dynamic> json) {
    return VocabWordDto(
      id: json['id'] as int,
      word: json['word'] as String? ?? '',
    );
  }

  VocabWord toDomain() => VocabWord(id: id, word: word);
}
