/// App-wide flags from `--dart-define`.
class AppConfig {
  static const bool offlineMode = bool.fromEnvironment(
    'OFFLINE_MODE',
    defaultValue: false,
  );
}
