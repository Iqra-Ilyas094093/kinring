/// Deployed URLs for the Cloudflare Workers (product doc Part 11).
/// `kinring-cron` (Phase 6) needs no client-side URL — it's push-only,
/// triggered by its own cron, never called from the app. These two ARE
/// called from the app, so their real `*.workers.dev` URL (from each
/// worker's `wrangler deploy` output) goes here — see the manual steps
/// list for exactly where to get each one.
class BackendConfig {
  BackendConfig._();

  /// Phase 7 — kinring-ringnow worker.
  static const String ringNowUrl = 'https://kinring-ringnow.iqrailyas093.workers.dev';

  /// Phase 9 — kinring-media-worker.
  static const String mediaWorkerUrl = 'https://kinring-media-worker.YOUR-SUBDOMAIN.workers.dev';
}
