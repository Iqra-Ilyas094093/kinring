/// Shared spacing, radius, and sizing scale.
///
/// Same rule as colors/text: screens should reference these constants
/// rather than writing raw padding/radius numbers, so the whole app's
/// rhythm can be tuned from one place.
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusPill = 999;

  static const double buttonHeight = 52;
  static const double inputHeight = 52;
}
