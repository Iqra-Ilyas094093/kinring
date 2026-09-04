import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../core/services/notify_service.dart';
import '../models/group_model.dart';
import '../models/notification_item.dart';

/// Single source of truth for group data — mirrors how [AuthViewModel]
/// owns auth. Provided once at the app root; screens never talk to
/// `FirebaseFirestore` directly for group data.
class GroupsViewModel extends ChangeNotifier {
  GroupsViewModel({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  String get _uid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('GroupsViewModel used with no signed-in user.');
    return uid;
  }

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Live stream of every group the current user belongs to. Screens
  /// (`GroupsScreen`, `HomeScreen`) build directly off this with a
  /// `StreamBuilder` — no manual refresh needed.
  Stream<List<GroupModel>> listenGroups() {
    return _db
        .collection('groups')
        .where('memberIds', arrayContains: _uid)
        .snapshots()
        .map((qs) => qs.docs.map(GroupModel.fromDoc).toList());
  }

  Stream<List<GroupMemberModel>> listenMembers(String groupId) {
    return _db
        .collection('groups')
        .doc(groupId)
        .collection('members')
        .snapshots()
        .map((qs) => qs.docs.map(GroupMemberModel.fromDoc).toList());
  }

  Stream<GroupModel?> listenGroup(String groupId) {
    return _db
        .collection('groups')
        .doc(groupId)
        .snapshots()
        .map((doc) => doc.exists ? GroupModel.fromDoc(doc) : null);
  }

  String _generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // no 0/O/1/I ambiguity
    final rand = Random.secure();
    final suffix = List.generate(6, (_) => chars[rand.nextInt(chars.length)]).join();
    return 'KR-$suffix';
  }

  Future<void> _ensureOwnUserDoc() async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _db.collection('users').doc(user.uid).set({
      'name': user.displayName ?? 'Member',
      'email': user.email,
      'photoUrl': user.photoURL,
    }, SetOptions(merge: true));
  }

  Future<GroupModel?> createGroup(String name, {String? photoUrl}) async {
    try {
      await _ensureOwnUserDoc();
      final uid = _uid;
      final user = _auth.currentUser;
      final code = _generateInviteCode();
      final groupRef = _db.collection('groups').doc();

      final batch = _db.batch();
      final group = GroupModel(
        id: groupRef.id,
        name: name.trim(),
        photoUrl: photoUrl,
        inviteCode: code,
        createdBy: uid,
        memberIds: [uid],
      );
      batch.set(groupRef, group.toCreateMap());
      batch.set(
        groupRef.collection('members').doc(uid),
        GroupMemberModel(
          uid: uid,
          role: 'admin',
          active: true,
          displayName: user?.displayName ?? 'Member',
          photoUrl: user?.photoURL,
        ).toMap(),
      );
      await batch.commit();

      // A group of one has nobody else to notify — this is a self-record
      // only, written directly (rules allow a user to write their own
      // notifications feed, no worker needed since there's no fan-out).
      await _db.collection('notifications').doc(uid).collection('items').add(
            NotificationItem(
              id: '',
              kind: NotificationKind.groupActivity,
              title: 'You created ${group.name}',
              groupId: group.id,
              ts: DateTime.now(),
            ).toMap(),
          );

      return group;
    } catch (e) {
      _errorMessage = 'Could not create group. Please try again.';
      notifyListeners();
      return null;
    }
  }

  /// Looks a group up by invite code without joining — used for the
  /// Join Group screen's live "group found" preview.
  Future<GroupModel?> lookupByCode(String code) async {
    final trimmed = code.trim().toUpperCase();
    if (trimmed.isEmpty) return null;
    final qs = await _db
        .collection('groups')
        .where('inviteCode', isEqualTo: trimmed)
        .limit(1)
        .get();
    if (qs.docs.isEmpty) return null;
    return GroupModel.fromDoc(qs.docs.first);
  }

  Future<GroupModel?> joinGroup(String code) async {
    try {
      await _ensureOwnUserDoc();
      final group = await lookupByCode(code);
      if (group == null) {
        _errorMessage = 'No group found with that invite code.';
        notifyListeners();
        return null;
      }
      final uid = _uid;
      final user = _auth.currentUser;
      final groupRef = _db.collection('groups').doc(group.id);
      final batch = _db.batch();
      batch.set(
        groupRef.collection('members').doc(uid),
        GroupMemberModel(
          uid: uid,
          role: 'member',
          active: true,
          displayName: user?.displayName ?? 'Member',
          photoUrl: user?.photoURL,
        ).toMap(),
      );
      batch.update(groupRef, {
        'memberIds': FieldValue.arrayUnion([uid]),
      });
      await batch.commit();

      // Phase 8 fix (notifications): tell the rest of the group someone
      // joined. Fire-and-forget — join already succeeded, a failed
      // courtesy ping shouldn't block returning the group to the caller.
      NotifyService.notify(
        groupId: group.id,
        kind: NotificationKind.groupActivity.name,
        title: '${user?.displayName ?? 'A new member'} joined ${group.name}',
      );

      return group;
    } catch (e) {
      _errorMessage = 'Could not join group. Please try again.';
      notifyListeners();
      return null;
    }
  }

  Future<void> renameGroup(String groupId, String newName) async {
    await _db.collection('groups').doc(groupId).update({'name': newName.trim()});
  }

  /// Phase 9 — group photo. Called after [MediaUploadService.uploadImage]
  /// returns the new photo's URL.
  Future<void> updateGroupPhoto(String groupId, String photoUrl) async {
    await _db.collection('groups').doc(groupId).update({'photoUrl': photoUrl});
  }

  Future<void> promoteMember(String groupId, String memberUid) async {
    await _db
        .collection('groups')
        .doc(groupId)
        .collection('members')
        .doc(memberUid)
        .update({'role': 'admin'});
  }

  Future<void> removeMember(String groupId, String memberUid) async {
    final groupRef = _db.collection('groups').doc(groupId);
    final batch = _db.batch();
    batch.delete(groupRef.collection('members').doc(memberUid));
    batch.update(groupRef, {
      'memberIds': FieldValue.arrayRemove([memberUid]),
    });
    await batch.commit();
  }

  Future<void> leaveGroup(String groupId) async {
    await removeMember(groupId, _uid);
  }

  Future<void> deleteGroup(String groupId) async {
    final groupRef = _db.collection('groups').doc(groupId);
    final members = await groupRef.collection('members').get();
    final batch = _db.batch();
    for (final m in members.docs) {
      batch.delete(m.reference);
    }
    batch.delete(groupRef);
    await batch.commit();
    // Note: events/statuses subcollections under this group are orphaned
    // by a client-side delete (Firestore doesn't cascade-delete
    // subcollections). Cleaning those up is a Cloudflare Worker job for
    // later phases, not part of Phase 1-3 scope.
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
