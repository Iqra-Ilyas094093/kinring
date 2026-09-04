import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../core/services/fcm_service.dart';
import '../core/services/google_auth_service.dart';
import '../core/services/notify_service.dart';
import '../models/auth_flow_status.dart';
import '../models/notification_item.dart';

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
    FirebaseFirestore? firestore,
  })  : _auth = firebaseAuth ?? FirebaseAuth.instance,
        _googleAuthService = googleAuthService ?? GoogleAuthService(),
        _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final GoogleAuthService _googleAuthService;
  final FirebaseFirestore _db;

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

  /// Updates the display name on the Firebase Auth user and mirrors
  /// name/phone onto `users/{uid}` (merge — doesn't clobber fields
  /// [GroupsViewModel] writes there, like `fcmTokens`). Used by
  /// [AccountSettingsScreen]'s Save button. Email changes need
  /// re-authentication in Firebase Auth and are out of scope for this
  /// screen's MVP form (the field is display-only until that flow
  /// exists).
  Future<bool> updateProfile({required String name, String? phone}) async {
    final user = _auth.currentUser;
    if (user == null) return false;
    try {
      await user.updateDisplayName(name.trim());
      await _db.collection('users').doc(user.uid).set({
        'name': name.trim(),
        if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
      }, SetOptions(merge: true));
      await _syncMemberDocsAndNotify(displayName: name.trim());
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Phase 9 — profile photo. Mirrors [updateProfile]'s shape: updates
  /// the Firebase Auth user's `photoURL` and the `users/{uid}` doc so
  /// [GroupsViewModel]'s denormalized member `photoUrl` picks it up next
  /// time it's re-written (join/promote), and any screen reading
  /// `currentUser.photoURL` directly stays in sync too.
  Future<bool> updatePhoto(String photoUrl) async {
    final user = _auth.currentUser;
    if (user == null) return false;
    try {
      await user.updatePhotoURL(photoUrl);
      await _db.collection('users').doc(user.uid).set({'photoUrl': photoUrl}, SetOptions(merge: true));
      await _syncMemberDocsAndNotify(photoUrl: photoUrl);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Every group member doc (`groups/{groupId}/members/{uid}`) carries
  /// its OWN denormalized `displayName`/`photoUrl` — copied at join
  /// time (see [GroupsViewModel.joinGroup]) so member lists render off
  /// one subcollection stream instead of a per-member `users/{uid}`
  /// read. That means [updateProfile]/[updatePhoto] updating `users/{uid}`
  /// alone was never actually visible to any group — this keeps every
  /// membership doc in sync too, then tells each group about it (skipped
  /// for a name/photo that's empty, since callers only pass what changed).
  Future<void> _syncMemberDocsAndNotify({String? displayName, String? photoUrl}) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final groupsSnap = await _db.collection('groups').where('memberIds', arrayContains: uid).get();

    final batch = _db.batch();
    for (final doc in groupsSnap.docs) {
      batch.update(doc.reference.collection('members').doc(uid), {
        if (displayName != null) 'displayName': displayName,
        if (photoUrl != null) 'photoUrl': photoUrl,
      });
    }
    await batch.commit();

    for (final doc in groupsSnap.docs) {
      NotifyService.notify(
        groupId: doc.id,
        kind: NotificationKind.profileUpdated.name,
        title: '${displayName ?? 'A member'} updated their profile',
      );
    }
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
