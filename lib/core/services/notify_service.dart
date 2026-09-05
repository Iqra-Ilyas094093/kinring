import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../constants/backend_config.dart';

/// Tells the rest of a group about something worth notifying them of —
/// a member joining, a new event, a profile update. POSTs to the
/// `kinring-notify` Worker, which writes a notification doc directly
/// into each target member's own `notifications/{uid}/items`
/// subcollection (client-side Firestore rules only let a user write
/// their own, so this has to go through a backend with elevated
/// access — same pattern as [RingNowService]) and sends a data-only FCM
/// push (`type: 'activity'`) so it lands live even if their app isn't
/// open.
///
/// `kind` must match one of [NotificationKind]'s `.name` values that
/// the worker accepts — currently `groupActivity`, `eventCreated`,
/// `profileUpdated`.
class NotifyService {
  NotifyService._();

  static Future<void> notify({
    required String groupId,
    required String kind,
    required String title,
    bool excludeSelf = true,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return; // Nothing to notify as — silently skip rather than throw; this is a courtesy ping, not core to the action that triggered it.
    final idToken = await user.getIdToken();

    try {
      final res = await http.post(
        Uri.parse(BackendConfig.notifyUrl),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'groupId': groupId, 'kind': kind, 'title': title, 'excludeSelf': excludeSelf}),
      );
      if (res.statusCode != 200) {
        debugPrint('NotifyService.notify failed (${res.statusCode}): ${res.body}');
      }
    } catch (e) {
      // Fire-and-forget by design (see call sites: join/create/update
      // flows already succeeded by the time this runs) — a failed
      // courtesy notification shouldn't surface as an error to the
      // user. But it should NOT be silent to a developer: this was
      // completely swallowed before, which is exactly how "notifyUrl is
      // still the placeholder, so every single call fails" went
      // undiagnosed — printed here so `flutter run`'s console shows the
      // real reason (e.g. a DNS failure on the placeholder host) instead
      // of nothing at all.
      debugPrint('NotifyService.notify error: $e');
    }
  }
}
