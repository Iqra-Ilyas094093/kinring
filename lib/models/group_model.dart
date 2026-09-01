import 'package:cloud_firestore/cloud_firestore.dart';

enum GroupRole { admin, member }

GroupRole _roleFromString(String? v) =>
    v == 'admin' ? GroupRole.admin : GroupRole.member;

String _roleToString(GroupRole r) => r == GroupRole.admin ? 'admin' : 'member';

/// Firestore doc: `groups/{groupId}`.
class Group {
  Group({
    required this.id,
    required this.name,
    required this.inviteCode,
    required this.createdBy,
    this.photoUrl,
    this.memberIds = const <String>[],
  });

  final String id;
  final String name;
  final String? photoUrl;
  final String inviteCode;
  final String createdBy;
  final List<String> memberIds;

  factory Group.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    return Group(
      id: doc.id,
      name: (d['name'] as String?) ?? '',
      photoUrl: d['photoUrl'] as String?,
      inviteCode: (d['inviteCode'] as String?) ?? '',
      createdBy: (d['createdBy'] as String?) ?? '',
      memberIds: List<String>.from(d['memberIds'] as List? ?? const []),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'photoUrl': photoUrl,
        'inviteCode': inviteCode,
        'createdBy': createdBy,
        'memberIds': memberIds,
      };
}

/// Firestore doc: `groups/{groupId}/members/{uid}`.
class GroupMember {
  GroupMember({
    required this.uid,
    required this.role,
    required this.joinedAt,
    this.active = true,
  });

  final String uid;
  final GroupRole role;
  final DateTime joinedAt;
  final bool active;

  GroupMember copyWith({GroupRole? role}) => GroupMember(
        uid: uid,
        role: role ?? this.role,
        joinedAt: joinedAt,
        active: active,
      );

  factory GroupMember.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    return GroupMember(
      uid: doc.id,
      role: _roleFromString(d['role'] as String?),
      joinedAt: (d['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      active: (d['active'] as bool?) ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
        'role': _roleToString(role),
        'joinedAt': Timestamp.fromDate(joinedAt),
        'active': active,
      };
}

/// A [GroupMember] joined with its `users/{uid}` profile (name/photo), for
/// screens that render a member list (Group Details, Manage Members).
/// [name] falls back to the uid if the user doc hasn't loaded/exists.
class GroupMemberProfile {
  GroupMemberProfile({required this.member, this.name, this.photoUrl});

  final GroupMember member;
  final String? name;
  final String? photoUrl;

  String get displayName => (name != null && name!.isNotEmpty) ? name! : member.uid;
  bool get isAdmin => member.role == GroupRole.admin;
}
