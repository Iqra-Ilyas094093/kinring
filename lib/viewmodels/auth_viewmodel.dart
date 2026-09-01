import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../core/services/fcm_service.dart';
import '../core/services/google_auth_service.dart';
import '../models/auth_flow_status.dart';

/// Single source of truth for authentication.
///
/// Provided once at the app root (see `app.dart`) so:
/// - [AuthGate] can watch [authStateChanges] to decide which screen to show.
/// - Login/Signup/ForgotPassword/EmailVerification screens can call the
///   same methods and read the same [status]/[errorMessage] without each
///   owning their own copy of this logic.
///
/// Screens never talk to `FirebaseAuth` or `GoogleAuthService` directly —
/// everything goes through here.
class AuthViewModel extends ChangeNotifier {
  AuthViewModel({
    FirebaseAuth? firebaseAuth,
    GoogleAuthService? googleAuthService,
  })  : _auth = firebaseAuth ?? FirebaseAuth.instance,
        _googleAuthService = googleAuthService ?? GoogleAuthService();

  final FirebaseAuth _auth;
  final GoogleAuthService _googleAuthService;

  AuthFlowStatus _status = AuthFlowStatus.idle;
  AuthFlowStatus get status => _status;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// The live Firebase session stream — [AuthGate] routes off this.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  void _startLoading() {
    _status = AuthFlowStatus.loading;
    _errorMessage = null;
    notifyListeners();
  }

  void _finishSuccess() {
    _status = AuthFlowStatus.success;
    _errorMessage = null;
    notifyListeners();
  }

  void _finishError(String message) {
    _status = AuthFlowStatus.error;
    _errorMessage = message;
    notifyListeners();
  }

  /// Clears a shown error without triggering another network call — call
  /// this when the user starts editing a field again after seeing an error.
  void clearError() {
    if (_status == AuthFlowStatus.error) {
      _status = AuthFlowStatus.idle;
      _errorMessage = null;
      notifyListeners();
    }
  }

  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    _startLoading();
    try {
      await _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
      _finishSuccess();
      return true;
    } on FirebaseAuthException catch (e) {
      _finishError(_messageForCode(e.code));
      return false;
    } catch (_) {
      _finishError('Something went wrong. Please try again.');
      return false;
    }
  }

  Future<bool> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    _startLoading();
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await credential.user?.updateDisplayName(name.trim());
      await credential.user?.sendEmailVerification();
      _finishSuccess();
      return true;
    } on FirebaseAuthException catch (e) {
      _finishError(_messageForCode(e.code));
      return false;
    } catch (_) {
      _finishError('Something went wrong. Please try again.');
      return false;
    }
  }

  /// Returns true on success, false on cancel or failure (check
  /// [errorMessage] to tell a real failure from a user-cancelled flow —
  /// cancellation leaves [status] at idle rather than error).
  Future<bool> signInWithGoogle() async {
    _startLoading();
    try {
      final idToken = await _googleAuthService.signIn();
      if (idToken == null) {
        // User closed the Google account picker — not an error.
        _status = AuthFlowStatus.idle;
        notifyListeners();
        return false;
      }
      final credential = GoogleAuthProvider.credential(idToken: idToken);
      await _auth.signInWithCredential(credential);
      _finishSuccess();
      return true;
    } on FirebaseAuthException catch (e) {
      _finishError(_messageForCode(e.code));
      return false;
    } catch (_) {
      _finishError(
        'Google sign-in failed. Make sure the Web client ID in '
        'google_auth_config.dart is set correctly.',
      );
      return false;
    }
  }

  Future<bool> sendPasswordResetEmail(String email) async {
    _startLoading();
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      _finishSuccess();
      return true;
    } on FirebaseAuthException catch (e) {
      _finishError(_messageForCode(e.code));
      return false;
    }
  }

  Future<void> resendVerificationEmail() async {
    await _auth.currentUser?.sendEmailVerification();
  }

  /// Reloads the current user from Firebase and reports whether their
  /// email is now verified. Used by [EmailVerificationScreen] to poll.
  Future<bool> reloadAndCheckVerified() async {
    await _auth.currentUser?.reload();
    return _auth.currentUser?.emailVerified ?? false;
  }

  Future<void> signOut() async {
    // Must run before _auth.signOut() — needs currentUser to still be
    // non-null to know which users/{uid} doc to pull the token off.
    await FcmService.clearTokenForCurrentUser();
    await _googleAuthService.signOut();
    await _auth.signOut();
  }

  String _messageForCode(String code) {
    switch (code) {
      case 'invalid-email':
        return 'That email address looks invalid.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Please choose a stronger password.';
      case 'network-request-failed':
        return 'Network error — check your connection.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}
