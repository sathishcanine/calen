import 'package:intl/intl.dart';

import '../config/api_config.dart';
import '../config/app_config.dart';
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
import 'spiritual_static_bundle.dart';

/// Calendar data from API or bundled offline SQLite (see [AppConfig.offlineMode]).
class CalendarRepository {
  CalendarRepository._({required ApiService? api, required LocalCalendarService? local})
      : _api = api,
        _local = local;

  final ApiService? _api;
  final LocalCalendarService? _local;

  bool get isOffline => _local != null;

  ApiService get _online {
    final api = _api;
    if (api == null) throw StateError('API unavailable in offline mode');
    return api;
  }

  LocalCalendarService get _offline {
    final local = _local;
    if (local == null) throw StateError('Local DB unavailable in online mode');
    return local;
  }

  static Future<CalendarRepository> create() async {
    if (AppConfig.offlineMode) {
      await LocalDatabase.instance.ensureInitialized();
      await SpiritualStaticBundle.instance.load();
      await PanchaPakshiEngine.instance.load();
      return CalendarRepository._(local: LocalCalendarService(), api: null);
    }
    return CalendarRepository._(api: ApiService(), local: null);
  }

  Future<HomeSummary> getHome({DateTime? date}) {
    if (_local != null) return _offline.fetchHome(date: date);
    return _online.fetchHome(date: date ?? DateTime.now());
  }

  Future<DailyCalendar> getDay(DateTime date) {
    if (_local != null) return _offline.fetchDay(date);
    return _online.fetchDay(cityId: ApiConfig.defaultCityId, date: date);
  }

  Future<HoraWeek> getHoraWeek(DateTime date) {
    if (_local != null) return _offline.fetchHoraWeek(date);
    return _online.fetchHoraWeek(cityId: ApiConfig.defaultCityId, date: date);
  }

  Future<GowriWeek> getGowriWeek(DateTime date) {
    if (_local != null) return _offline.fetchGowriWeek(date);
    return _online.fetchGowriWeek(cityId: ApiConfig.defaultCityId, date: date);
  }

  Future<InauspiciousWeek> getInauspiciousWeek(DateTime date) {
    if (_local != null) return _offline.fetchInauspiciousWeek(date);
    return _online.fetchInauspiciousWeek(cityId: ApiConfig.defaultCityId, date: date);
  }

  Future<VastuDays> getVastuDays(int year) {
    if (_local != null) return _offline.fetchVastuDays(year);
    return _online.fetchVastuDays(cityId: ApiConfig.defaultCityId, year: year);
  }

  Future<List<VastuArticle>> getVastuArticles() {
    if (_local != null) return _offline.fetchVastuArticles();
    return _online.fetchVastuArticles();
  }

  Future<List<int>> getVastuYears() {
    if (_local != null) return _offline.fetchVastuYears();
    return _online.fetchVastuYears();
  }

  Future<List<PanchaPakshiArticle>> getPanchaPakshiArticles() {
    if (_local != null) return _offline.fetchPanchaPakshiArticles();
    return _online.fetchPanchaPakshiArticles();
  }

  Future<PanchaPakshiArticleDetail> getPanchaPakshiArticle(int id) {
    if (_local != null) return _offline.fetchPanchaPakshiArticle(id);
    return _online.fetchPanchaPakshiArticle(id);
  }

  Future<List<PanchaPakshiNakshatra>> getPanchaPakshiNakshatras() {
    if (_local != null) return _offline.fetchPanchaPakshiNakshatras();
    return _online.fetchPanchaPakshiNakshatras();
  }

  Future<List<PanchaPakshiPakshaOption>> getPanchaPakshiPakshaOptions() {
    if (_local != null) return _offline.fetchPanchaPakshiPakshaOptions();
    return _online.fetchPanchaPakshiPakshaOptions();
  }

  Future<List<int>> getPanchaPakshiYears() {
    if (_local != null) return _offline.fetchPanchaPakshiYears();
    return _online.fetchPanchaPakshiYears();
  }

  Future<PanchaPakshiResult> calculatePanchaPakshi({
    required int nakshatraIndex,
    required String birthPakshaId,
    required DateTime date,
  }) {
    if (_local != null) {
      return _offline.fetchPanchaPakshiCalculate(
        nakshatraIndex: nakshatraIndex,
        birthPakshaId: birthPakshaId,
        date: date,
      );
    }
    return _online.fetchPanchaPakshiCalculate(
      cityId: ApiConfig.defaultCityId,
      nakshatraIndex: nakshatraIndex,
      birthPakshaId: birthPakshaId,
      date: date,
    );
  }

  Future<MonthCalendar> getMonth(int year, int month) {
    if (_local != null) return _offline.fetchMonth(year, month);
    return _online.fetchMonth(cityId: ApiConfig.defaultCityId, year: year, month: month);
  }

  Future<List<JyotishNakshatra>> getJyotishNakshatras() {
    if (_local != null) return _offline.fetchJyotishNakshatras();
    return _online.fetchJyotishNakshatras();
  }

  Future<List<JyotishRashi>> getJyotishRashis() {
    if (_local != null) return _offline.fetchJyotishRashis();
    return _online.fetchJyotishRashis();
  }

  Future<NazhigaiResult> convertNazhigai({
    required DateTime date,
    int hour = 0,
    int minute = 0,
    bool toNazhigai = true,
    int nazhigai = 1,
    int vinadi = 0,
  }) {
    if (_local != null) {
      return _offline.fetchNazhigaiConvert(
        date: date,
        hour: hour,
        minute: minute,
        toNazhigai: toNazhigai,
        nazhigai: nazhigai,
        vinadi: vinadi,
      );
    }
    return _online.fetchNazhigaiConvert(
      cityId: ApiConfig.defaultCityId,
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
    if (_local != null) {
      return _offline.fetchChandrashtamam(birthRashiIndex: birthRashiIndex, date: date);
    }
    return _online.fetchChandrashtamam(
      cityId: ApiConfig.defaultCityId,
      birthRashiIndex: birthRashiIndex,
      date: date,
    );
  }

  Future<NumerologyResult> getNumerology({required String name, required DateTime date}) {
    if (_local != null) return _offline.fetchNumerology(name: name, date: date);
    return _online.fetchNumerology(cityId: ApiConfig.defaultCityId, name: name, date: date);
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
    if (_local != null) {
      return _offline.fetchMarriagePorutham(
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
      cityId: ApiConfig.defaultCityId,
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
    if (_local != null) {
      return _offline.fetchTarabalam(birthNakshatraIndex: birthNakshatraIndex, date: date);
    }
    return _online.fetchTarabalam(
      cityId: ApiConfig.defaultCityId,
      birthNakshatraIndex: birthNakshatraIndex,
      date: date,
    );
  }

  Future<List<PalangalCategory>> getPalangalCategories() {
    if (_local != null) return _offline.fetchPalangalCategories();
    return _online.fetchPalangalCategories();
  }

  Future<List<PalangalArticle>> getPalangalArticles(String categoryId) {
    if (_local != null) return _offline.fetchPalangalArticles(categoryId);
    return _online.fetchPalangalArticles(categoryId);
  }

  Future<PalangalArticleDetail> getPalangalArticle(String categoryId, int articleId) {
    if (_local != null) return _offline.fetchPalangalArticle(categoryId, articleId);
    return _online.fetchPalangalArticle(categoryId, articleId);
  }

  String formatDate(DateTime d) => DateFormat('yyyy-MM-dd').format(d);
}
