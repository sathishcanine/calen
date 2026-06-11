import 'package:intl/intl.dart';

import '../config/api_config.dart';
import '../models/daily_calendar.dart';
import '../models/gowri_week.dart';
import '../models/hora_week.dart';
import '../models/inauspicious_week.dart';
import '../models/month_calendar.dart';
import 'api_service.dart';

/// All calendar data is loaded from the backend API on each request.
/// Local SQLite caching can be added later when the app is stable.
class CalendarRepository {
  CalendarRepository({ApiService? api}) : _api = api ?? ApiService();

  final ApiService _api;

  Future<HomeSummary> getHome({DateTime? date}) =>
      _api.fetchHome(date: date ?? DateTime.now());

  Future<DailyCalendar> getDay(DateTime date) => _api.fetchDay(
        cityId: ApiConfig.defaultCityId,
        date: date,
      );

  Future<HoraWeek> getHoraWeek(DateTime date) => _api.fetchHoraWeek(
        cityId: ApiConfig.defaultCityId,
        date: date,
      );

  Future<GowriWeek> getGowriWeek(DateTime date) => _api.fetchGowriWeek(
        cityId: ApiConfig.defaultCityId,
        date: date,
      );

  Future<InauspiciousWeek> getInauspiciousWeek(DateTime date) => _api.fetchInauspiciousWeek(
        cityId: ApiConfig.defaultCityId,
        date: date,
      );

  Future<MonthCalendar> getMonth(int year, int month) => _api.fetchMonth(
        cityId: ApiConfig.defaultCityId,
        year: year,
        month: month,
      );

  String formatDate(DateTime d) => DateFormat('yyyy-MM-dd').format(d);
}
