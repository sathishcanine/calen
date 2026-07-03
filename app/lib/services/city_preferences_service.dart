import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../models/city.dart';

/// Persists the user's chosen city for panchangam timings.
class CityPreferencesService {
  CityPreferencesService._();

  static final CityPreferencesService instance = CityPreferencesService._();

  static const _keyCityId = 'selected_city_id';
  static const _keyCityJson = 'selected_city_json';
  static const _keyOnboardingDone = 'city_onboarding_done';
  static const _keyLocationDiscoverySeen = 'location_discovery_seen';

  /// Matches bundled assets/data/calendar.db (Chennai 2026).
  static const defaultCity = City(
    id: 'chennai',
    nameEn: 'Chennai',
    nameTa: 'சென்னை',
    displayName: 'Chennai - சென்னை',
    lat: 13.0827,
    lon: 80.2707,
    tzOffset: 5.5,
    country: 'IN',
    isDefault: true,
  );

  SharedPreferences? _prefs;
  City? _selectedCity;

  City? get selectedCity => _selectedCity;

  String get cityId => _selectedCity?.id ?? ApiConfig.defaultCityId;

  String get displayName =>
      _selectedCity?.displayName ?? defaultCity.displayName;

  bool get isDefaultCity => cityId == ApiConfig.defaultCityId;

  bool get hasCompletedOnboarding =>
      _prefs?.getBool(_keyOnboardingDone) ?? false;

  bool get hasSeenLocationDiscovery =>
      _prefs?.getBool(_keyLocationDiscoverySeen) ?? false;

  Future<void> markLocationDiscoverySeen() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setBool(_keyLocationDiscoverySeen, true);
  }

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs!.getString(_keyCityJson);
    if (raw != null) {
      try {
        _selectedCity = City.fromJson(
          jsonDecode(raw) as Map<String, dynamic>,
        );
      } catch (_) {
        _selectedCity = null;
      }
    }
    final id = _prefs!.getString(_keyCityId);
    if (_selectedCity == null && id != null && id.isNotEmpty) {
      _selectedCity = City(
        id: id,
        nameEn: id,
        nameTa: id,
        displayName: id,
        lat: 0,
        lon: 0,
        tzOffset: 5.5,
        country: 'IN',
      );
    }
    // Fresh install: persist bundled default (Chennai 2026 in calendar.db).
    if (_selectedCity == null && id == null) {
      await setCity(defaultCity, markOnboardingDone: false);
    }
  }

  Future<void> setCity(City city, {bool markOnboardingDone = true}) async {
    _prefs ??= await SharedPreferences.getInstance();
    _selectedCity = city;
    await _prefs!.setString(_keyCityId, city.id);
    await _prefs!.setString(_keyCityJson, jsonEncode({
      'id': city.id,
      'name_en': city.nameEn,
      'name_ta': city.nameTa,
      'display_name': city.displayName,
      'lat': city.lat,
      'lon': city.lon,
      'tz_offset': city.tzOffset,
      'country': city.country,
      'timezone': city.timezone,
      'is_default': city.isDefault,
    }));
    if (markOnboardingDone) {
      await _prefs!.setBool(_keyOnboardingDone, true);
    }
  }
}
