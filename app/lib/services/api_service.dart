import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../config/api_config.dart';
import '../models/daily_calendar.dart';
import '../models/gowri_week.dart';
import '../models/hora_week.dart';
import '../models/inauspicious_week.dart';
import '../models/month_calendar.dart';

class ApiService {
  ApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Uri _uri(String path, [Map<String, String>? query]) {
    return Uri.parse('${ApiConfig.baseUrl}$path').replace(queryParameters: query);
  }

  Future<HomeSummary> fetchHome({String cityId = ApiConfig.defaultCityId, DateTime? date}) async {
    final d = date ?? DateTime.now();
    final dateStr = DateFormat('yyyy-MM-dd').format(d);
    final res = await _client.get(_uri('/home', {'city_id': cityId, 'date': dateStr}));
    if (res.statusCode != 200) throw Exception('Home failed: ${res.body}');
    return HomeSummary.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<DailyCalendar> fetchDay({
    required String cityId,
    required DateTime date,
  }) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final res = await _client.get(_uri('/calendar/day', {'city_id': cityId, 'date': dateStr}));
    if (res.statusCode != 200) throw Exception('Day failed: ${res.body}');
    return DailyCalendar.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<List<DailyCalendar>> fetchDailyBundle({
    required String cityId,
    required DateTime from,
    int days = 30,
  }) async {
    final fromStr = DateFormat('yyyy-MM-dd').format(from);
    final res = await _client.get(_uri('/sync/daily-bundle', {
      'city_id': cityId,
      'from': fromStr,
      'days': days.toString(),
    }));
    if (res.statusCode != 200) throw Exception('Bundle failed: ${res.body}');
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final items = data['items'] as List<dynamic>;
    return items.map((e) => DailyCalendar.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<HoraWeek> fetchHoraWeek({
    required String cityId,
    required DateTime date,
  }) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final res = await _client.get(_uri('/spiritual/hora-week', {
      'city_id': cityId,
      'date': dateStr,
    }));
    if (res.statusCode != 200) throw Exception('Hora week failed: ${res.body}');
    return HoraWeek.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<GowriWeek> fetchGowriWeek({
    required String cityId,
    required DateTime date,
  }) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final res = await _client.get(_uri('/spiritual/gowri-week', {
      'city_id': cityId,
      'date': dateStr,
    }));
    if (res.statusCode != 200) throw Exception('Gowri week failed: ${res.body}');
    return GowriWeek.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<InauspiciousWeek> fetchInauspiciousWeek({
    required String cityId,
    required DateTime date,
  }) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final res = await _client.get(_uri('/spiritual/inauspicious-week', {
      'city_id': cityId,
      'date': dateStr,
    }));
    if (res.statusCode != 200) throw Exception('Inauspicious week failed: ${res.body}');
    return InauspiciousWeek.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<MonthCalendar> fetchMonth({
    required String cityId,
    required int year,
    required int month,
  }) async {
    final res = await _client.get(_uri('/calendar/month', {
      'city_id': cityId,
      'year': year.toString(),
      'month': month.toString(),
    }));
    if (res.statusCode != 200) throw Exception('Month failed: ${res.body}');
    return MonthCalendar.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }
}
