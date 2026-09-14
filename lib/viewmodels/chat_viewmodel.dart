import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../core/services/notify_service.dart';
import '../models/chat_message_model.dart';
import '../models/notification_item.dart' show NotificationKind;

/// Single source of truth for chat data — same pattern as
/// [GroupsViewModel]/[EventStatusViewModel]: provided once at the app
/// root, screens never talk to `FirebaseFirestore` directly.
///
/// Text-only (product doc Part 15.1) — deliberately no attachment
/// upload, no edit/delete, no typing indicators. If any of those get
/// added later that's a new, separate method here, not a change to
/// [sendMessage].
class ChatViewModel extends ChangeNotifier {
  ChatViewModel({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  CollectionReference<Map<String, dynamic>> _messages(String groupId) =>
      _db.collection('groups').doc(groupId).collection('messages');

  /// Live stream of one group's messages, oldest-first — the message
  /// list screen reverses this for a bottom-anchored, newest-at-bottom
  /// chat view (standard `ListView(reverse: true)` pattern).
  Stream<List<ChatMessageModel>> listenMessages(String groupId) {
    return _messages(groupId)
        .orderBy('sentAt', descending: true)
        .limit(200)
        .snapshots()
        .map((qs) => qs.docs.map(ChatMessageModel.fromDoc).toList());
  }

  /// Called when a member opens a group's chat thread — resets their
  /// unread count for that group to zero going forward.
  Future<void> markThreadRead({required String groupId}) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _db.collection('groups').doc(groupId).collection('members').doc(uid).set({
      'lastReadChatAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// The signed-in user's own `lastReadChatAt` for one group — feeds
  /// [listenUnreadCount] on the Chat tab's list.
  Stream<DateTime?> listenMyLastRead(String groupId) {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(null);
    return _db.collection('groups').doc(groupId).collection('members').doc(uid).snapshots().map((doc) {
      final ts = doc.data()?['lastReadChatAt'];
      return ts is Timestamp ? ts.toDate() : null;
    });
  }

  /// Live count of messages sent after [since] — `since: null` means
  /// "never read this thread", so every message counts. Used per-row on
  /// the Chat tab list (same nested-`StreamBuilder`-per-item pattern
  /// [GroupsScreen] already uses for its member-avatar stack), not a
  /// server-maintained counter — there's no Cloud Functions on the
  /// Spark plan to keep one in sync.
  Stream<int> listenUnreadCount({required String groupId, required DateTime? since}) {
    final query = since == null
        ? _messages(groupId)
        : _messages(groupId).where('sentAt', isGreaterThan: Timestamp.fromDate(since));
    return query.snapshots().map((qs) => qs.docs.length);
  }

  /// Sends a message and denormalizes the preview fields onto the group
  /// doc in the same batch, so the Chat tab's group list (built off the
  /// existing `GroupsViewModel.listenGroups` stream) shows an accurate
  /// "last message" preview without a second read per group.
  Future<void> sendMessage({required String groupId, required String text}) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final messageRef = _messages(groupId).doc();
      final groupRef = _db.collection('groups').doc(groupId);
      final batch = _db.batch();

      batch.set(
        messageRef,
        ChatMessageModel(
          id: messageRef.id,
          senderUid: user.uid,
          text: trimmed,
          senderDisplayName: user.displayName ?? 'Member',
          senderPhotoUrl: user.photoURL,
        ).toCreateMap(),
      );
      batch.update(groupRef, {
        'lastMessageText': trimmed,
        'lastMessageAt': FieldValue.serverTimestamp(),
        'lastMessageSenderUid': user.uid,
      });

      await batch.commit();

      // This is the piece that was missing before: the message itself
      // landed fine (Firestore's live listener is why it always worked
      // "in the app"), but nothing ever told kinring-notify to push it
      // to members who don't have the app open. Fire-and-forget, same
      // as every other NotifyService call site — the message already
      // sent successfully by the time this runs.
      NotifyService.notify(
        groupId: groupId,
        kind: NotificationKind.chatMessage.name,
        title: '${user.displayName ?? 'Someone'}: $trimmed',
      );
    } catch (e) {
      _errorMessage = 'Could not send message. Please try again.';
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
