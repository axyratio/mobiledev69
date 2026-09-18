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
    required this.cefrLevel,
    required this.cefrLevelFilterEnabled,
    required this.highlightFilterByLevelEnabled,
    required this.oidcProvider,
  });

  final int id;
  final String email;
  final String name;
  final String themePreference;

  /// The learner's own CEFR level (default A1) — Story Detail only
  /// highlights target words at or above it.
  final String cefrLevel;

  /// Whether the create-story word randomizer should be limited to
  /// [cefrLevel] and below instead of the whole vocabulary bank.
  final bool cefrLevelFilterEnabled;

  /// Whether Story Detail highlighting (target and bonus words alike) is
  /// limited to [cefrLevel] and above. Off means every vocabulary-bank word
  /// found in the story gets highlighted, regardless of level.
  final bool highlightFilterByLevelEnabled;

  /// The OIDC provider this account is linked to (e.g. "google"), or empty
  /// for an email/password account — shown as a badge on Settings.
  final String oidcProvider;
}
