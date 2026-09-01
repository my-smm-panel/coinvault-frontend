/// API configuration for CoinVault.
///
/// Base URL for the CoinVault backend (Render) and auth worker (Cloudflare).
/// Override at build time with:
///   flutter run --dart-define=API_BASE_URL=https://coinvault-api.onrender.com
class ApiConfig {
  ApiConfig._();

  /// Backend API (Render) — main REST API.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://coinvault-api.onrender.com',
  );

  /// Auth endpoint (Cloudflare Worker) — Firebase token exchange + JWT proxy.
  static const String authWorkerUrl = String.fromEnvironment(
    'AUTH_WORKER_URL',
    defaultValue: 'https://coinvault-auth.coinvault.workers.dev',
  );

  /// Firebase web API key (public, safe to embed).
  static const String firebaseApiKey = String.fromEnvironment('FIREBASE_API_KEY');

  /// Firebase project id.
  static const String firebaseProjectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
    defaultValue: 'coinvault-be301',
  );

  /// App display name.
  static const String appName = 'CoinVault';
}
