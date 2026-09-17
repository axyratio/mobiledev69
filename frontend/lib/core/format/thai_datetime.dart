const List<String> _thaiMonthsShort = [
  'ม.ค.',
  'ก.พ.',
  'มี.ค.',
  'เม.ย.',
  'พ.ค.',
  'มิ.ย.',
  'ก.ค.',
  'ส.ค.',
  'ก.ย.',
  'ต.ค.',
  'พ.ย.',
  'ธ.ค.',
];

/// Formats [dateTime] as "17 ก.ย. 2569 · 22:14" — day, Thai month
/// abbreviation, Buddhist year, and 24h time, matching the Story Detail
/// mockup's date line.
String formatThaiDateTime(DateTime dateTime) {
  final day = dateTime.day;
  final month = _thaiMonthsShort[dateTime.month - 1];
  final buddhistYear = dateTime.year + 543;
  final hour = dateTime.hour.toString().padLeft(2, '0');
  final minute = dateTime.minute.toString().padLeft(2, '0');
  return '$day $month $buddhistYear · $hour:$minute';
}
