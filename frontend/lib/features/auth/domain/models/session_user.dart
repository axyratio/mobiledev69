/// Domain model for the signed-in user (SSOT for the auth feature).
///
/// Pure — no JSON parsing here, that's [SessionUserDto]'s job in the data
/// layer. ViewModels and views only ever see this type.
class SessionUser {
  const SessionUser({
    required this.id,
    required this.email,
    required this.name,
    required this.themePreference,
  });

  final int id;
  final String email;
  final String name;
  final String themePreference;
}
