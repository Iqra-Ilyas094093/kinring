import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/notification_item.dart';

/// Backs [NotificationsScreen] (doc 5.5.4) — same "single source of
/// truth, provided once at app root" shape as [GroupsViewModel] and
/// [EventsViewModel]. The docs themselves under `notifications/{uid}/items`
/// are written server-side by the `kinring-notify` Worker (member
/// joined/event created/profile updated — see [NotifyService]) using its
/// elevated service-account access, since Firestore rules only let a
/// user write their own feed directly. This ViewModel only reads.
class NotificationsViewModel extends ChangeNotifier {
  NotificationsViewModel({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  /// Live stream for the Notifications screen's `StreamBuilder` — most
  /// recent first. Empty stream (not an error) when signed out, so the
  /// screen's `StreamBuilder` just shows its existing empty state.
  Stream<List<NotificationItem>> listenNotifications() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    return _db
        .collection('notifications')
        .doc(uid)
        .collection('items')
        .orderBy('ts', descending: true)
        .limit(50)
        .snapshots()
        .map((qs) => qs.docs.map(NotificationItem.fromDoc).toList());
  }

  /// Backs the Home tab bell icon's badge. A plain count of unread docs
  /// — cheap enough at this app's scale not to need a Firestore
  /// aggregate `count()` query, and it's already live via the same
  /// `read` field [markAllRead] flips.
  Stream<int> listenUnreadCount() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(0);
    return _db
        .collection('notifications')
        .doc(uid)
        .collection('items')
        .where('read', isEqualTo: false)
        .snapshots()
        .map((qs) => qs.docs.length);
  }

  /// Called when the Notifications screen opens — clears the bell
  /// badge. Only touches docs actually still unread, so repeat calls
  /// (reopening the screen) are cheap no-ops once caught up.
  Future<void> markAllRead() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final unread = await _db
        .collection('notifications')
        .doc(uid)
        .collection('items')
        .where('read', isEqualTo: false)
        .get();
    if (unread.docs.isEmpty) return;
    final batch = _db.batch();
    for (final doc in unread.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }
}
