/// Deployed backend config (product doc Part 11, Phase 9 amended).
/// `kinring-cron` (Phase 6) needs no client-side URL — it's push-only,
/// triggered by its own cron, never called from the app. `ringNowUrl`
/// is the `kinring-ringnow` Worker's real `*.workers.dev` URL, from its
/// `wrangler deploy` output.
///
/// Phase 9 no longer uses a Cloudflare Worker + R2 — photo storage is
/// Cloudinary instead (unsigned upload preset, no backend needed to
/// broker it). `cloudinaryCloudName` + `cloudinaryUploadPreset` come
/// from your Cloudinary dashboard — see manual steps doc.
class BackendConfig {
  BackendConfig._();

  /// Phase 7 — kinring-ringnow worker.
  static const String ringNowUrl = 'https://kinring-ringnow.iqrailyas093.workers.dev';

  /// Notifications — kinring-notify worker (generic activity fan-out:
  /// member joined, event created, profile updated). Fill in after its
  /// own `wrangler deploy`.
  static const String notifyUrl = 'https://kinring-notify.iqrailyas093.workers.dev';

  /// Phase 9 — Cloudinary, cloud name from dashboard home page.
  static const String cloudinaryCloudName = 'hfkht08v';

  static const String cloudinaryUploadPreset = 'kinring_photos';
}

