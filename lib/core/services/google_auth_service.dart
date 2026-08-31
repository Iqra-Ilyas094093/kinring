import 'package:google_sign_in/google_sign_in.dart';

import '../constants/google_auth_config.dart';

/// Wraps `google_sign_in` v7+ (the `GoogleSignIn.instance` API —
/// `initialize()` + `authenticate()` — replaced the old `GoogleSignIn().
/// signIn()` used in v6 and earlier).
///
/// This is a "service" in the MVVM sense: it only talks to the Google SDK
/// and hands back plain data (an ID token). It knows nothing about
/// Firebase or the UI — [AuthViewModel] is what turns the token into a
/// Firebase credential.
class GoogleAuthService {
  GoogleAuthService() {
    _initFuture = GoogleSignIn.instance.initialize(
      serverClientId: GoogleAuthConfig.serverClientId,
    );
  }

  late final Future<void> _initFuture;

  /// Runs the interactive Google sign-in flow and returns the ID token,
  /// or `null` if the user cancelled.
  Future<String?> signIn() async {
    await _initFuture;

    if (!GoogleSignIn.instance.supportsAuthenticate()) {
      throw StateError(
        'GoogleSignIn.authenticate() is not supported on this platform. '
        'Android is the only supported platform for this MVP.',
      );
    }

    try {
      final GoogleSignInAccount account = await GoogleSignIn.instance.authenticate();
      final GoogleSignInAuthentication auth = account.authentication;
      return auth.idToken;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return null;
      }
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _initFuture;
    await GoogleSignIn.instance.signOut();
  }
}
