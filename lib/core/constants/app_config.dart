/// Build-time configuration supplied with --dart-define.
///
/// Example:
///   flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=YOUR_WEB_CLIENT_ID.apps.googleusercontent.com
/// See SETUP.md.
class AppConfig {
  AppConfig._();

  /// Google OAuth web (server) client ID used by google_sign_in to mint the
  /// ID token Firebase needs. Empty means "not provided": we pass null and the
  /// Android plugin falls back to default_web_client_id from google-services.json.
  static const String _googleServerClientId =
      String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');

  static String? get googleServerClientId =>
      _googleServerClientId.trim().isEmpty ? null : _googleServerClientId.trim();
}
