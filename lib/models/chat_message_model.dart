import 'package:cloud_firestore/cloud_firestore.dart';

/// `groups/{groupId}/messages/{messageId}` — product doc Part 15.2.
///
/// Text-only by design (Part 15.1) — deliberately no attachment/media
/// fields, no edited/deleted flags, no reactions. `senderDisplayName`/
/// `senderPhotoUrl` are denormalized at send time, same pattern already
/// used for `GroupMemberModel` (Part 11.1), so the message list never
/// needs a per-message `users/{uid}` read.
class ChatMessageModel {
  ChatMessageModel({
    required this.id,
    required this.senderUid,
    required this.text,
    this.senderDisplayName,
    this.senderPhotoUrl,
    this.sentAt,
  });

  final String id;
  final String senderUid;
  final String text;
  final String? senderDisplayName;
  final String? senderPhotoUrl;
  final DateTime? sentAt;

  factory ChatMessageModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    final ts = data['sentAt'];
    return ChatMessageModel(
      id: doc.id,
      senderUid: data['senderUid'] as String? ?? '',
      text: data['text'] as String? ?? '',
      senderDisplayName: data['senderDisplayName'] as String?,
      senderPhotoUrl: data['senderPhotoUrl'] as String?,
      sentAt: ts is Timestamp ? ts.toDate() : null,
    );
  }

  Map<String, dynamic> toCreateMap() => {
        'senderUid': senderUid,
        'text': text,
        'senderDisplayName': senderDisplayName,
        'senderPhotoUrl': senderPhotoUrl,
        'sentAt': FieldValue.serverTimestamp(),
      };
}
