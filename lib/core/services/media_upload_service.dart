import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../constants/backend_config.dart';

/// Phase 9 — uploads a picked image to the `kinring-media-worker` R2
/// bucket and returns the worker-served URL to save on the Firestore
/// doc's `photoUrl` field (`users/{uid}` or `groups/{groupId}`). Firebase's
/// free Spark plan has no Cloud Storage, so this Worker + R2 stands in
/// for it (product doc Part 11 Phase 9).
class MediaUploadService {
  MediaUploadService._();

  static String _contentTypeFor(String path) {
    switch (path.split('.').last.toLowerCase()) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  static Future<String> uploadImage(File file) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('MediaUploadService.uploadImage called with no signed-in user.');
    }
    final idToken = await user.getIdToken();
    final bytes = await file.readAsBytes();

    final res = await http.post(
      Uri.parse('${BackendConfig.mediaWorkerUrl}/upload'),
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': _contentTypeFor(file.path),
      },
      body: bytes,
    );

    if (res.statusCode != 200) {
      throw Exception('Upload failed (${res.statusCode}): ${res.body}');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return body['url'] as String;
  }
}
