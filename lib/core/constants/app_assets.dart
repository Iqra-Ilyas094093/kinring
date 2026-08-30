/// Central registry of asset paths. Screens/widgets should reference these
/// constants instead of writing `'assets/logo/...'` strings inline.
class AppAssets {
  AppAssets._();

  static const String logoFull = 'assets/logo/full_logo.png';
  static const String logoMonogram = 'assets/logo/monogram.png';
  static const String logoWordmark = 'assets/logo/wordmark.png';
  static const String logoLeftBar = 'assets/logo/left_bar_logo.png';
  static const String appIcon = 'assets/logo/app_icon.png';
  static const String appIconForeground = 'assets/logo/app_icon_foreground.png';

  /// Not bundled yet — drop a Google "G" mark PNG/SVG here when available.
  /// GoogleSignInButton falls back to a text "G" until this asset exists.
  static const String googleLogo = 'assets/icons/google_logo.png';
}
