/// API base URL for network features (status stories, non-default cities, etc.).
/// Bundled assets: calendar.db + pancha_pakshi_db.csv only.
class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE',
    defaultValue: 'http://10.0.2.2:4000/api/v1',
  );

  static const String defaultCityId = 'chennai';
}
