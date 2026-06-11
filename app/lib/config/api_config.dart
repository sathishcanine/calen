/// API base URL.
/// Android emulator: http://10.0.2.2:4000/api/v1
/// Physical device: use your machine LAN IP, e.g. http://192.168.1.5:4000/api/v1
class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE',
    defaultValue: 'http://10.0.2.2:4000/api/v1',
  );

  static const String defaultCityId = 'chennai';
}
