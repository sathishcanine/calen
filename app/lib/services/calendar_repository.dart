import 'package:intl/intl.dart';

import '../config/app_config.dart';
import '../config/api_config.dart';
import '../models/city.dart';
import '../models/daily_calendar.dart';
import '../models/gowri_week.dart';
import '../models/hora_week.dart';
import '../models/inauspicious_week.dart';
import '../models/month_calendar.dart';
import '../models/jyotish.dart';
import '../models/palangal.dart';
import '../models/pancha_pakshi.dart';
import '../models/vastu.dart';
import 'api_service.dart';
import 'local_calendar_service.dart';
import 'local_database.dart';
import 'pancha_pakshi_engine.dart';
import 'city_preferences_service.dart';
import 'spiritual_static_bundle.dart';

/// Hybrid data access: bundled Chennai 2026 SQLite offline + API for other cities.
class CalendarRepository {
  CalendarRepository._({required ApiService? api, required LocalCalendarService local})
      : _api = api,
        _local = local;

  final ApiService? _api;
  final LocalCalendarService _local;

  /// True when calendar reads come from bundled assets (no network).
  /// Chennai always uses bundled calendar.db — even when OFFLINE_MODE=false.
  bool get usesBundledCalendar =>
      AppConfig.offlineMode || CityPreferencesService.instance.isDefaultCity;

  bool get isOffline => AppConfig.offlineMode;

  String get cityId => CityPreferencesService.instance.cityId;

  String get cityDisplayName => CityPreferencesService.instance.displayName;

  bool get _hasApi => _api != null && !AppConfig.offlineMode;

  Future<List<City>> getCities() async {
    if (!_hasApi) return _bundledCities();
    try {
      return await _api!.fetchCities();
    } catch (_) {
      return _bundledCities();
    }
  }

  /// Bundled calendar.db contains Chennai 2026 only.
  List<City> _bundledCities() => [CityPreferencesService.defaultCity];

  ApiService get _online {
    final api = _api;
    if (api == null) throw StateError('API unavailable');
    return api;
  }

  static Future<CalendarRepository> create() async {
    await CityPreferencesService.instance.load();
    await LocalDatabase.instance.ensureInitialized();
    await SpiritualStaticBundle.instance.load();
    await PanchaPakshiEngine.instance.load();

    final local = LocalCalendarService(cityId: ApiConfig.defaultCityId);
    if (AppConfig.offlineMode) {
      return CalendarRepository._(api: null, local: local);
    }
    return CalendarRepository._(api: ApiService(), local: local);
  }

  Future<HomeSummary> getHome({DateTime? date}) {
    if (usesBundledCalendar) return _local.fetchHome(date: date);
    return _online.fetchHome(cityId: cityId, date: date ?? DateTime.now());
  }

  Future<DailyCalendar> getDay(DateTime date) {
    if (usesBundledCalendar) return _local.fetchDay(date);
    return _online.fetchDay(cityId: cityId, date: date);
  }

  Future<HoraWeek> getHoraWeek(DateTime date) {
    if (usesBundledCalendar) return _local.fetchHoraWeek(date);
    return _online.fetchHoraWeek(cityId: cityId, date: date);
  }

  Future<GowriWeek> getGowriWeek(DateTime date) {
    if (usesBundledCalendar) return _local.fetchGowriWeek(date);
    return _online.fetchGowriWeek(cityId: cityId, date: date);
  }

  Future<InauspiciousWeek> getInauspiciousWeek(DateTime date) {
    if (usesBundledCalendar) return _local.fetchInauspiciousWeek(date);
    return _online.fetchInauspiciousWeek(cityId: cityId, date: date);
  }

  Future<VastuDays> getVastuDays(int year) {
    if (usesBundledCalendar) return _local.fetchVastuDays(year);
    return _online.fetchVastuDays(cityId: cityId, year: year);
  }

  Future<List<VastuArticle>> getVastuArticles() {
    return _local.fetchVastuArticles();
  }

  Future<List<int>> getVastuYears() {
    return _local.fetchVastuYears();
  }

  Future<List<PanchaPakshiArticle>> getPanchaPakshiArticles() {
    return _local.fetchPanchaPakshiArticles();
  }

  Future<PanchaPakshiArticleDetail> getPanchaPakshiArticle(int id) {
    if (usesBundledCalendar) return _local.fetchPanchaPakshiArticle(id);
    return _online.fetchPanchaPakshiArticle(id);
  }

  Future<List<PanchaPakshiNakshatra>> getPanchaPakshiNakshatras() {
    return _local.fetchPanchaPakshiNakshatras();
  }

  Future<List<PanchaPakshiPakshaOption>> getPanchaPakshiPakshaOptions() {
    return _local.fetchPanchaPakshiPakshaOptions();
  }

  Future<List<int>> getPanchaPakshiYears() {
    return _local.fetchPanchaPakshiYears();
  }

  Future<PanchaPakshiResult> calculatePanchaPakshi({
    required int nakshatraIndex,
    required String birthPakshaId,
    required DateTime date,
  }) {
    if (usesBundledCalendar) {
      return _local.fetchPanchaPakshiCalculate(
        nakshatraIndex: nakshatraIndex,
        birthPakshaId: birthPakshaId,
        date: date,
      );
    }
    return _online.fetchPanchaPakshiCalculate(
      cityId: cityId,
      nakshatraIndex: nakshatraIndex,
      birthPakshaId: birthPakshaId,
      date: date,
    );
  }

  Future<MonthCalendar> getMonth(int year, int month) {
    if (usesBundledCalendar) return _local.fetchMonth(year, month);
    return _online.fetchMonth(cityId: cityId, year: year, month: month);
  }

  Future<List<JyotishNakshatra>> getJyotishNakshatras() {
    return _local.fetchJyotishNakshatras();
  }

  Future<List<JyotishRashi>> getJyotishRashis() {
    return _local.fetchJyotishRashis();
  }

  Future<NazhigaiResult> convertNazhigai({
    required DateTime date,
    int hour = 0,
    int minute = 0,
    bool toNazhigai = true,
    int nazhigai = 1,
    int vinadi = 0,
  }) {
    if (!_hasApi) {
      return _local.fetchNazhigaiConvert(
        date: date,
        hour: hour,
        minute: minute,
        toNazhigai: toNazhigai,
        nazhigai: nazhigai,
        vinadi: vinadi,
      );
    }
    return _online.fetchNazhigaiConvert(
      cityId: cityId,
      date: date,
      hour: hour,
      minute: minute,
      toNazhigai: toNazhigai,
      nazhigai: nazhigai,
      vinadi: vinadi,
    );
  }

  Future<ChandrashtamamResult> getChandrashtamam({
    required int birthRashiIndex,
    required DateTime date,
  }) {
    if (!_hasApi) {
      return _local.fetchChandrashtamam(birthRashiIndex: birthRashiIndex, date: date);
    }
    return _online.fetchChandrashtamam(
      cityId: cityId,
      birthRashiIndex: birthRashiIndex,
      date: date,
    );
  }

  Future<NumerologyResult> getNumerology({required String name, required DateTime date}) {
    if (!_hasApi) {
      return _local.fetchNumerology(name: name, date: date);
    }
    return _online.fetchNumerology(cityId: cityId, name: name, date: date);
  }

  Future<MarriagePoruthamResult> getMarriagePorutham({
    required DateTime person1Date,
    required int person1Hour,
    required int person1Minute,
    int? person1Nakshatra,
    required DateTime person2Date,
    required int person2Hour,
    required int person2Minute,
    int? person2Nakshatra,
  }) {
    if (!_hasApi) {
      return _local.fetchMarriagePorutham(
        person1Date: person1Date,
        person1Hour: person1Hour,
        person1Minute: person1Minute,
        person1Nakshatra: person1Nakshatra,
        person2Date: person2Date,
        person2Hour: person2Hour,
        person2Minute: person2Minute,
        person2Nakshatra: person2Nakshatra,
      );
    }
    return _online.fetchMarriagePorutham(
      cityId: cityId,
      person1Date: person1Date,
      person1Hour: person1Hour,
      person1Minute: person1Minute,
      person1Nakshatra: person1Nakshatra,
      person2Date: person2Date,
      person2Hour: person2Hour,
      person2Minute: person2Minute,
      person2Nakshatra: person2Nakshatra,
    );
  }

  Future<TarabalamResult> getTarabalam({
    required int birthNakshatraIndex,
    required DateTime date,
  }) {
    if (!_hasApi) {
      return _local.fetchTarabalam(birthNakshatraIndex: birthNakshatraIndex, date: date);
    }
    return _online.fetchTarabalam(
      cityId: cityId,
      birthNakshatraIndex: birthNakshatraIndex,
      date: date,
    );
  }

  Future<List<PalangalCategory>> getPalangalCategories() {
    return _local.fetchPalangalCategories();
  }

  Future<List<PalangalArticle>> getPalangalArticles(String categoryId) {
    return _local.fetchPalangalArticles(categoryId);
  }

  Future<PalangalArticleDetail> getPalangalArticle(String categoryId, int articleId) {
    return _local.fetchPalangalArticle(categoryId, articleId);
  }

  String formatDate(DateTime d) => DateFormat('yyyy-MM-dd').format(d);
}
