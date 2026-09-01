import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/group_model.dart';

/// Group backend (product doc Part 5.6 / roadmap Phase 2).
///
/// Same pattern as [AuthViewModel]: screens never talk to `Firestore`
/// directly, everything goes through here. Reads are exposed as
/// `Stream`s (`.snapshots()`) so every screen updates live — no manual
/// refresh, no pull-to-refresh needed anywhere in the Group flow.
class GroupsViewModel extends ChangeNotifier {
  GroupsViewModel({
    FirebaseFirestore? firestore,
    FirebaseAuth? firebaseAuth,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _auth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  String get _uid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('GroupsViewModel used while signed out.');
    return uid;
  }

  CollectionReference<Map<String, dynamic>> get _groups => _db.collection('groups');

  DocumentReference<Map<String, dynamic>> _groupDoc(String groupId) => _groups.doc(groupId);

  CollectionReference<Map<String, dynamic>> _membersCol(String groupId) =>
      _groupDoc(groupId).collection('members');

  // ---- reads (live) ----------------------------------------------------

  /// Groups the current user belongs to — powers the Groups tab / Home
  /// "Your Groups" section. Live: updates the moment a member doc is
  /// added/removed anywhere, no refresh needed.
  Stream<List<Group>> listenGroups() {
    return _groups
        .where('memberIds', arrayContains: _uid)
        .snapshots()
        .map((snap) => snap.docs.map(Group.fromDoc).toList());
  }

  /// A single group doc, live — for Group Details / Group Settings
  /// headers (name, photo) that can change while the screen is open.
  Stream<Group?> watchGroup(String groupId) {
    return _groupDoc(groupId).snapshots().map((doc) => doc.exists ? Group.fromDoc(doc) : null);
  }

  /// Member list, live — Group Details, Manage Members, Live Status all
  /// key off this same stream so an admin promotion or a member leaving
  /// shows up everywhere instantly.
  Stream<List<GroupMember>> listenMembers(String groupId) {
    return _membersCol(groupId).snapshots().map((snap) => snap.docs.map(GroupMember.fromDoc).toList());
  }

  /// Current user's role in a group — drives `isAdmin` checks in the UI
  /// (Admin Panel entry, Delete Group row, promote/remove menu).
  Stream<GroupRole?> watchMyRole(String groupId) {
    return _membersCol(groupId).doc(_uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return GroupMember.fromDoc(doc).role;
    });
  }

  /// Member list joined with `users/{uid}` profiles (name/photo), for
  /// screens that render names, not just uids — Group Details, Manage
  /// Members.
  ///
  /// Live on the *member* subcollection (add/remove/promote shows up
  /// instantly); the `users/{uid}` profile lookups inside are one-shot
  /// `.get()`s re-run each time the member list changes. Good enough for
  /// MVP group sizes — a member editing their own name won't re-push
  /// this stream until something else about the group changes. Revisit
  /// with a denormalized name-on-member-doc if that's ever an issue.
  Stream<List<GroupMemberProfile>> listenMembersWithProfiles(String groupId) {
    return _membersCol(groupId).snapshots().asyncMap((snap) async {
      final members = snap.docs.map(GroupMember.fromDoc).toList();
      final profiles = await Future.wait(members.map((m) async {
        final userDoc = await _db.collection('users').doc(m.uid).get();
        final d = userDoc.data();
        return GroupMemberProfile(
          member: m,
          name: d?['name'] as String?,
          photoUrl: d?['photoUrl'] as String?,
        );
      }));
      return profiles;
    });
  }

  /// One-off lookup by invite code — Join Group screen's live preview
  /// before the user commits to joining. Not a stream: this only needs
  /// to run once per code entered, not stay subscribed.
  Future<Group?> previewGroupByCode(String code) async {
    final normalized = code.trim().toUpperCase();
    if (normalized.isEmpty) return null;
    final snap = await _groups.where('inviteCode', isEqualTo: normalized).limit(1).get();
    if (snap.docs.isEmpty) return null;
    return Group.fromDoc(snap.docs.first);
  }

  // ---- writes ------------------------------------------------------------

  /// Creates a group doc + the creator's own member doc (role: admin) in
  /// one atomic batch, so a group is never briefly "adminless" if the
  /// second write failed.
  Future<Group> createGroup(String name) async {
    final uid = _uid;
    final groupRef = _groups.doc();
    final code = _generateInviteCode();

    final group = Group(
      id: groupRef.id,
      name: name.trim(),
      createdBy: uid,
      inviteCode: code,
      memberIds: [uid],
    );

    final batch = _db.batch();
    batch.set(groupRef, group.toMap());
    batch.set(
      groupRef.collection('members').doc(uid),
      GroupMember(uid: uid, role: GroupRole.admin, joinedAt: DateTime.now()).toMap(),
    );
    await batch.commit();

    return group;
  }

  /// Looks up a group by invite code, then adds the current user as a
  /// member (subdoc + `memberIds` array) in one batch.
  Future<Group> joinGroup(String code) async {
    final uid = _uid;
    final group = await previewGroupByCode(code);
    if (group == null) {
      throw StateError('No group found for that invite code.');
    }

    final groupRef = _groupDoc(group.id);
    final batch = _db.batch();
    batch.set(
      groupRef.collection('members').doc(uid),
      GroupMember(uid: uid, role: GroupRole.member, joinedAt: DateTime.now()).toMap(),
    );
    batch.update(groupRef, {
      'memberIds': FieldValue.arrayUnion([uid]),
    });
    await batch.commit();

    return group;
  }

  Future<void> renameGroup(String groupId, String name) async {
    await _groupDoc(groupId).update({'name': name.trim()});
  }

  Future<void> promoteMember(String groupId, String uid) async {
    await _membersCol(groupId).doc(uid).update({'role': 'admin'});
  }

  Future<void> removeMember(String groupId, String uid) async {
    final groupRef = _groupDoc(groupId);
    final batch = _db.batch();
    batch.delete(groupRef.collection('members').doc(uid));
    batch.update(groupRef, {
      'memberIds': FieldValue.arrayRemove([uid]),
    });
    await batch.commit();
  }

  /// Current user leaving — same write as [removeMember] but always
  /// targets the caller's own uid (rules only allow self-delete or admin).
  Future<void> leaveGroup(String groupId) => removeMember(groupId, _uid);

  Future<void> deleteGroup(String groupId) async {
    final groupRef = _groupDoc(groupId);
    final members = await groupRef.collection('members').get();
    final batch = _db.batch();
    for (final doc in members.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(groupRef);
    await batch.commit();
    // Note: this does not cascade-delete groups/{id}/events (Phase 3+) —
    // once Event backend exists, delete that subcollection here too.
  }

  static const _codeChars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // no 0/O/1/I

  String _generateInviteCode() {
    final rand = Random.secure();
    final body = List.generate(5, (_) => _codeChars[rand.nextInt(_codeChars.length)]).join();
    return 'KR-$body';
  }
}
