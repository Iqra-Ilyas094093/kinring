import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/chat_message_model.dart';

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
