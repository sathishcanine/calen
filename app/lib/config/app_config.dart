/// App-wide flags from `--dart-define`.
class AppConfig {
  /// When true, API is disabled entirely. Chennai 2026 bundled DB is always loaded.
  static const bool offlineMode = bool.fromEnvironment(
    'OFFLINE_MODE',
    defaultValue: false,
  );
}
