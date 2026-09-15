import '../../domain/models/session_user.dart';

/// Wire format for the user object returned by `/api/auth/me/`,
/// `/api/auth/login/` and `/api/auth/register/`. Confined to the data
/// layer — [toDomain] is the only way out, so the rest of the app never
/// sees a raw JSON key name.
class SessionUserDto {
  const SessionUserDto({
    required this.id,
    required this.email,
    required this.name,
    required this.themePreference,
  });

  final int id;
  final String email;
  final String name;
  final String themePreference;

  factory SessionUserDto.fromJson(Map<String, dynamic> json) {
    return SessionUserDto(
      id: json['id'] as int,
      email: json['email'] as String? ?? '',
      name: json['name'] as String? ?? '',
      themePreference: json['theme_preference'] as String? ?? 'light',
    );
  }

  SessionUser toDomain() {
    return SessionUser(id: id, email: email, name: name, themePreference: themePreference);
  }
}
