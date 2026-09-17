/// CEFR levels the vocabulary bank uses, ordered easiest to hardest.
const List<String> cefrLevels = ['A1', 'A2', 'B1', 'B2'];

int _cefrLevelIndex(String level) {
  final index = cefrLevels.indexOf(level);
  return index == -1 ? 0 : index;
}

/// True when a word at [wordLevel] should be highlighted for a learner who
/// selected [selectedLevel] — i.e. the word is at or above what they chose.
/// Words below the selected level are treated as already known and are left
/// unhighlighted.
bool cefrLevelMeetsSelection(String wordLevel, String selectedLevel) {
  return _cefrLevelIndex(wordLevel) >= _cefrLevelIndex(selectedLevel);
}
