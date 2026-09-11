class AppConstants {
  AppConstants._();

  static const String appName = 'ConnectCall';
  static const String tagline = 'Connect with anyone, anywhere.';
  static const String version = '1.0.0';

  // Demo credentials
  static const String demoEmail = 'demo@connectcall.app';
  static const String demoPassword = 'password123';

  // Timing
  static const int splashDurationMs = 2000;
  static const int callRingingDurationMs = 3000;
  static const int callConnectingDurationMs = 1500;
  static const int searchDebounceMs = 300;

  // Validation
  static const int minPasswordLength = 6;
  static const int maxNameLength = 50;

  // UI
  static const double minTouchTarget = 48.0;
  static const double callControlSize = 64.0;
  static const double callEndButtonSize = 72.0;
  static const double avatarSizeSm = 40.0;
  static const double avatarSizeMd = 56.0;
  static const double avatarSizeLg = 80.0;
  static const double avatarSizeXl = 120.0;
  static const double avatarSizeCall = 140.0;
}
