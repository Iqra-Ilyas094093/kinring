import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../constants/backend_config.dart';

/// Phase 7 — client side of the admin "Ring Now" broadcast (product doc
/// Part 4 / 5.9.2 / 11). POSTs the caller's Firebase ID token + groupId
/// (+ eventId, once the caller's created a broadcast event doc — see
/// EventsViewModel.createBroadcastEvent) to the `kinring-ringnow`
/// Worker, which verifies admin membership server-side and pushes an
/// instant alarm to every member's device(s), bypassing schedule and
/// silent/DND. Passing eventId through lets every member's push carry
/// the same real event id, so their Live Status/statuses writes land on
/// the SAME doc the admin's own screen is watching — this is push-only
/// by design; see `AdminPanelScreen` for the local `EventTrigger.fire`
/// call that still runs alongside this for immediate feedback on the
/// admin's own screen.
class RingNowService {
  RingNowService._();

  static Future<void> ringNow(String groupId, {String? eventId}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('RingNowService.ringNow called with no signed-in user.');
    }
    final idToken = await user.getIdToken();

    final res = await http.post(
      Uri.parse(BackendConfig.ringNowUrl),
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'groupId': groupId, if (eventId != null) 'eventId': eventId}),
    );

    if (res.statusCode != 200) {
      throw Exception('Ring Now failed (${res.statusCode}): ${res.body}');
    }
  }
}
