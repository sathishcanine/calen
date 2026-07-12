/// App-wide flags from `--dart-define`.
class AppConfig {
  /// When true, API is disabled entirely and bundled calendar data is loaded.
  static const bool offlineMode = bool.fromEnvironment(
    'OFFLINE_MODE',
    defaultValue: false,
  );
}
