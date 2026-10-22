/// Build-time configuration supplied with --dart-define.
///
/// Values are intentionally not hardcoded. Example:
///   flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=... --dart-define=OWNER_EMAIL=...
/// See DEMO_SETUP.md.
class AppConfig {
  AppConfig._();

  /// Google OAuth web (server) client ID used by google_sign_in to mint the
  /// ID token Firebase needs. Empty means "not provided": we pass null and the
  /// Android plugin falls back to default_web_client_id from google-services.json.
  static const String _googleServerClientId =
      String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');

  static String? get googleServerClientId =>
      _googleServerClientId.trim().isEmpty ? null : _googleServerClientId.trim();

  /// Agency owner's email. When signed in with it, the manager gets the owner's
  /// display name. Empty means no special-casing.
  static const String ownerEmail = String.fromEnvironment('OWNER_EMAIL');

  /// Owner display name used with [ownerEmail].
  static const String ownerName =
      String.fromEnvironment('OWNER_NAME', defaultValue: 'Ishraq Rafi');

  static bool isOwnerEmail(String? email) {
    final owner = ownerEmail.trim().toLowerCase();
    return owner.isNotEmpty && (email?.trim().toLowerCase() ?? '') == owner;
  }
}
