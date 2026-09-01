import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore doc: `users/{uid}`.
///
/// `fcmTokens` filled in Phase 5 (FCM). Present now so the shape matches
/// the roadmap and downstream ViewModels (Phase 2+) don't need a schema
/// change later.
class AppUser {
  AppUser({
    required this.uid,
    required this.name,
    required this.email,
    this.photoUrl,
    this.fcmTokens = const <String>[],
  });

  final String uid;
  final String name;
  final String email;
  final String? photoUrl;
  final List<String> fcmTokens;

  factory AppUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    return AppUser(
      uid: doc.id,
      name: (d['name'] as String?) ?? '',
      email: (d['email'] as String?) ?? '',
      photoUrl: d['photoUrl'] as String?,
      fcmTokens: List<String>.from(d['fcmTokens'] as List? ?? const []),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'email': email,
        'photoUrl': photoUrl,
        'fcmTokens': fcmTokens,
      };
}
