import 'package:cloud_firestore/cloud_firestore.dart';

/// `groups/{groupId}` — product doc Phase 1 schema.
class GroupModel {
  GroupModel({
    required this.id,
    required this.name,
    required this.inviteCode,
    required this.createdBy,
    required this.memberIds,
    this.photoUrl,
  });

  final String id;
  final String name;
  final String? photoUrl;
  final String inviteCode;
  final String createdBy;
  final List<String> memberIds;

  int get memberCount => memberIds.length;

  factory GroupModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    return GroupModel(
      id: doc.id,
      name: data['name'] as String? ?? '',
      photoUrl: data['photoUrl'] as String?,
      inviteCode: data['inviteCode'] as String? ?? '',
      createdBy: data['createdBy'] as String? ?? '',
      memberIds: List<String>.from(data['memberIds'] as List? ?? const []),
    );
  }

  Map<String, dynamic> toCreateMap() => {
        'name': name,
        'photoUrl': photoUrl,
        'inviteCode': inviteCode,
        'createdBy': createdBy,
        'memberIds': memberIds,
        'createdAt': FieldValue.serverTimestamp(),
      };
}

/// `groups/{groupId}/members/{uid}` — role + join metadata. `displayName`/
/// `photoUrl` are denormalized onto the member doc at join time (not in
/// the original doc schema) so the member list can render in real time
/// with a single subcollection stream instead of one `users/{uid}` read
/// per member.
class GroupMemberModel {
  GroupMemberModel({
    required this.uid,
    required this.role,
    required this.active,
    this.displayName,
    this.photoUrl,
    this.joinedAt,
  });

  final String uid;
  final String role; // 'admin' | 'member'
  final bool active;
  final String? displayName;
  final String? photoUrl;
  final DateTime? joinedAt;

  bool get isAdmin => role == 'admin';

  factory GroupMemberModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    final ts = data['joinedAt'];
    return GroupMemberModel(
      uid: doc.id,
      role: data['role'] as String? ?? 'member',
      active: data['active'] as bool? ?? true,
      displayName: data['displayName'] as String?,
      photoUrl: data['photoUrl'] as String?,
      joinedAt: ts is Timestamp ? ts.toDate() : null,
    );
  }

  Map<String, dynamic> toMap() => {
        'role': role,
        'active': active,
        'displayName': displayName,
        'photoUrl': photoUrl,
        'joinedAt': FieldValue.serverTimestamp(),
      };
}
