import 'package:flutter/foundation.dart';

import '../models/auth_status.dart';

/// ViewModel for [SplashScreen].
///
/// Holds no UI code. It exposes [status] and notifies listeners when it
/// changes; the screen only reads state and reacts — it never contains
/// the session-check logic itself.
///
/// `checkSession()` is currently a stub (brief delay, then "logged out")
/// since Firebase Auth isn't wired in yet. Replace the body of this method
/// with a real `FirebaseAuth.instance.currentUser` + email-verified check
/// later; nothing in `SplashScreen` will need to change.
class SplashViewModel extends ChangeNotifier {
  AuthStatus _status = AuthStatus.checking;
  AuthStatus get status => _status;

  Future<void> checkSession() async {
    _status = AuthStatus.checking;
    notifyListeners();

    // TODO(auth): replace with real Firebase session check.
    await Future.delayed(const Duration(milliseconds: 300));

    _status = AuthStatus.loggedOut;
    notifyListeners();
  }
}
