/// API base URL — used only when user picks a city other than bundled Chennai.
/// Chennai 2026 always comes from assets/data/calendar.db (no API needed).
class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE',
    defaultValue: 'http://10.0.2.2:4000/api/v1',
  );

  static const String defaultCityId = 'chennai';
}
