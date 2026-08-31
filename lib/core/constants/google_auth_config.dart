/// Config for Google Sign-In.
///
/// MANUAL STEP REQUIRED — see the "Web client ID" note below. Nothing here
/// works until you replace [serverClientId] with your real value.
class GoogleAuthConfig {
  GoogleAuthConfig._();

  /// The OAuth 2.0 "Web client" ID — required on Android even though it
  /// says "Web". This is how Firebase verifies the ID token Google hands
  /// back actually belongs to your project.
  ///
  /// Where to get it:
  /// 1. Go to Google Cloud Console → APIs & Services → Credentials
  ///    (make sure the project selected matches your Firebase project —
  ///    "kinring-30eb7" per your google-services.json).
  /// 2. Under "OAuth 2.0 Client IDs" look for the one of type "Web
  ///    application" — usually auto-named "Web client (auto created by
  ///    Google Service)". This gets created automatically the first time
  ///    you enable Google as a Sign-in provider in
  ///    Firebase Console → Authentication → Sign-in method.
  /// 3. Copy that client ID (ends in `.apps.googleusercontent.com`) and
  ///    paste it below.
  static const String serverClientId =
      '614410360657-tqnk58alj2rbk6e71s8qcrvuj7aed6a5.apps.googleusercontent.com';
}
