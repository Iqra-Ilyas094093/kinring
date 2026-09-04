import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../constants/backend_config.dart';

/// Phase 9 (amended) — uploads a picked image directly to Cloudinary via
/// its unsigned upload API, and returns the `secure_url` to save on the
/// Firestore doc's `photoUrl` field (`users/{uid}` or `groups/{groupId}`).
///
/// No Cloudflare Worker in this path anymore: an unsigned upload preset
/// (Cloudinary dashboard → Settings → Upload) lets the app POST straight
/// from the device with just the cloud name + preset name, no secret key
/// on the client and no server round-trip to broker the upload. This
/// replaces the earlier `kinring-media-worker` (R2) design — that
/// worker's `wrangler.toml`/`index.js` can be deleted, nothing calls it
/// anymore.
class MediaUploadService {
  MediaUploadService._();

  static Future<String> uploadImage(File file) async {
    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/${BackendConfig.cloudinaryCloudName}/image/upload',
    );

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = BackendConfig.cloudinaryUploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);

    if (res.statusCode != 200) {
      throw Exception('Upload failed (${res.statusCode}): ${res.body}');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return body['secure_url'] as String;
  }
}
