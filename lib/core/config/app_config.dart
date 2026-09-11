class AppConfig {
  AppConfig._();

  // Placeholder for future backend integration
  // These values should come from environment variables or a secure config
  static const String supabaseUrl = '';
  static const String supabaseAnonKey = '';
  static const String livekitUrl = '';

  // Firebase configuration is handled via google-services.json (Android)
  // and GoogleService-Info.plist (iOS)

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
