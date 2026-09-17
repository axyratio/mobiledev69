/// Formats a past [DateTime] as a short Thai relative-time string, matching
/// the design reference's copy (e.g. "2 ชม.ที่แล้ว", "เมื่อวาน", "3 วันก่อน").
String formatRelativeTimeThai(DateTime dateTime) {
  final difference = DateTime.now().difference(dateTime);

  if (difference.inMinutes < 1) return 'เมื่อสักครู่';
  if (difference.inMinutes < 60) return '${difference.inMinutes} นาทีที่แล้ว';
  if (difference.inHours < 24) return '${difference.inHours} ชม.ที่แล้ว';
  if (difference.inDays == 1) return 'เมื่อวาน';
  if (difference.inDays < 7) return '${difference.inDays} วันก่อน';
  final weeks = (difference.inDays / 7).floor();
  if (difference.inDays < 30) return '$weeks สัปดาห์ก่อน';
  final months = (difference.inDays / 30).floor();
  if (difference.inDays < 365) return '$months เดือนก่อน';
  final years = (difference.inDays / 365).floor();
  return '$years ปีก่อน';
}
