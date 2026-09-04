import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import '../../firebase_options.dart';
import '../../models/event_draft.dart';
import 'alarm_scheduler.dart';
import 'event_trigger.dart';
import 'local_notifications_service.dart';

/// Phase 5 — FCM push. Secondary sync layer on top of the Phase 4 local
/// alarm (cron backup pushes, Ring Now broadcasts) plus the channel for
/// non-event notifications (member cleared/snoozed/joined — doc 5.5.4).
///
/// Data-message contract this expects in `message.data` (set by the
/// Phase 6/7 Cloudflare Workers, not built yet — this is the client side
/// only): always data-only, never a `notification` block, so display is
/// 100% controlled here (same full-screen-intent path as the local
/// alarm, not the OS default tray notification).
///   - `type`: 'alarm' | 'reminder' | 'activity'
///     - 'alarm' covers both the cron backup trigger AND admin "Ring
///       Now" (Ring Now is just an admin-broadcast alarm — same UI).
///     - 'reminder': push-only by design (doc 5.8.4), never full-screen.
///     - 'activity': cleared/snoozed/joined/event-created/profile-updated
///       etc, sent by the `kinring-notify` Worker. The Firestore doc
///       under notifications/{uid}/items is already written server-side
///       (with elevated access, since a client can only write its own);
///       this push is just the live nudge — `kind`/`title`/`groupId`
///       come through as flat string fields (see fcm.js `extra`), no
///       `draft` key for this type.
///   - `draft`: jsonEncode(EventDraft.toJson()) — required for
///     alarm/reminder, matches [AlarmScheduler]'s local payload shape
///     exactly so both paths converge on the same [EventTrigger.fire].
///
/// Not a ViewModel — same "service" tier as [AlarmScheduler] and
/// [LocalNotificationsService]; it calls into the latter to actually
/// display anything, and reuses [EventDraft] rather than a separate
/// wire model.
class FcmService {
  FcmService._();

  static GlobalKey<NavigatorState>? _navigatorKey;

  static Future<void> initialize({required GlobalKey<NavigatorState> navigatorKey}) async {
    _navigatorKey = navigatorKey;

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Android 13+ POST_NOTIFICATIONS — same permission LocalNotificationsService
    // already requests for the local alarm path; requesting twice is a no-op
    // once granted, so it's safe to call again here rather than thread a
    // "was this already asked" flag through.
    await LocalNotificationsService.requestPermission();

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleOpenedMessage);

    FirebaseMessaging.instance.onTokenRefresh.listen(_saveToken);
  }

  /// Cold-start case: app was fully killed, user tapped a push
  /// notification. Mirrors [LocalNotificationsService.routeIfLaunchedFromNotification] —
  /// call once from `main()` after `runApp`.
  static Future<void> routeIfLaunchedFromMessage() async {
    final message = await FirebaseMessaging.instance.getInitialMessage();
    if (message != null) _route(message.data);
  }

  /// Call after the user is confirmed signed in (see `AuthGate`) — logs
  /// the current device token under `users/{uid}.fcmTokens` so any
  /// backend push (cron backup, Ring Now, activity) can reach this
  /// device. `arrayUnion` keeps every signed-in device's token, since
  /// one account can be logged in on more than one phone.
  static Future<void> syncTokenForCurrentUser() async {
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) await _saveToken(token);
  }

  static Future<void> _saveToken(String token) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return; // Token refreshed with nobody signed in — next syncTokenForCurrentUser() call catches it.
    await FirebaseFirestore.instance.collection('users').doc(uid).set(
      {
        'fcmTokens': FieldValue.arrayUnion([token]),
      },
      SetOptions(merge: true),
    );
  }

  /// Removes this device's token on sign-out so a stale token doesn't
  /// keep receiving pushes for an account no longer active here. Call
  /// from `AuthViewModel.signOut()` (before the actual Firebase sign-out,
  /// while `currentUser` is still non-null).
  static Future<void> clearTokenForCurrentUser() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final token = await FirebaseMessaging.instance.getToken();
    if (uid == null || token == null) return;
    await FirebaseFirestore.instance.collection('users').doc(uid).set(
      {
        'fcmTokens': FieldValue.arrayRemove([token]),
      },
      SetOptions(merge: true),
    );
  }

  /// App open and in foreground — data messages don't auto-display, so
  /// this is the one path that shows UI directly instead of via a
  /// notification tap.
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final type = message.data['type'];
    if (type == 'activity') {
      // Firestore doc already written server-side by kinring-notify —
      // NotificationsScreen's own live listener picks it up on its own.
      // This is just the heads-up nudge for whichever screen is open
      // right now.
      await LocalNotificationsService.showActivityNotification(
        id: DateTime.now().millisecondsSinceEpoch & 0x7fffffff,
        title: message.data['title'] ?? 'Group activity',
        groupId: message.data['groupId'] ?? '',
      );
      return;
    }

    final context = _navigatorKey?.currentState?.context;
    final draftJson = message.data['draft'];
    if (context == null || draftJson == null) return;
    final draft = EventDraft.fromJson(jsonDecode(draftJson) as Map<String, dynamic>);
    EventTrigger.fire(context, draft);
  }

  /// App was backgrounded (not killed) and the user tapped the
  /// notification [firebaseMessagingBackgroundHandler] posted.
  static void _handleOpenedMessage(RemoteMessage message) => _route(message.data);

  static void _route(Map<String, dynamic> data) {
    final context = _navigatorKey?.currentState?.context;
    if (context == null) return;
    final draftJson = data['draft'];
    if (draftJson == null) return;
    final draft = EventDraft.fromJson(jsonDecode(draftJson as String) as Map<String, dynamic>);
    EventTrigger.fire(context, draft);
  }
}

/// Top-level, `@pragma('vm:entry-point')` — required by `firebase_messaging`:
/// runs in its own headless background isolate when a data message
/// arrives with the app backgrounded/killed, same constraint as
/// [alarmFireCallback] in `alarm_scheduler.dart`. Must re-init Firebase
/// itself since this isolate never ran `main()`.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final type = message.data['type'];
  final draftJson = message.data['draft'] as String?;

  if (type == 'activity') {
    // Firestore doc already written server-side by kinring-notify — this
    // is the background heads-up nudge only.
    await LocalNotificationsService.showActivityNotification(
      id: DateTime.now().millisecondsSinceEpoch & 0x7fffffff,
      title: message.data['title'] ?? 'Group activity',
      groupId: message.data['groupId'] ?? '',
    );
    return;
  }
  if (draftJson == null) return;

  final json = jsonDecode(draftJson) as Map<String, dynamic>;
  final draft = EventDraft.fromJson(json);
  // Same id formula as the local AlarmManager trigger (AlarmScheduler)
  // whenever this push is for a real persisted event — so a cron backup
  // push and the local alarm collapse into one notification instead of
  // two, and cancelForEvent's dismiss() call still reaches it. Ring Now
  // broadcasts (no eventId) fall back to a timestamp-derived id.
  final id = draft.eventId != null
      ? AlarmScheduler.alarmIdFor(draft.eventId!)
      : DateTime.now().millisecondsSinceEpoch & 0x7fffffff;

  if (type == 'reminder') {
    await LocalNotificationsService.showReminderNotification(
      id: id,
      title: draft.title.isEmpty ? 'Reminder' : draft.title,
      body: draft.groupName,
      payloadJson: draftJson,
    );
  } else {
    // 'alarm' (cron backup) or Ring Now broadcast — same full-screen path
    // the local AlarmManager trigger uses, so it still bypasses silent/DND.
    await LocalNotificationsService.showAlarmNotification(
      id: id,
      title: '⏰ ${draft.title.isEmpty ? "Alarm" : draft.title}',
      body: draft.groupName,
      payloadJson: draftJson,
    );
  }
}
