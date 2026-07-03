import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

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

class ApiService {
  ApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Uri _uri(String path, [Map<String, String>? query]) {
    return Uri.parse('${ApiConfig.baseUrl}$path').replace(queryParameters: query);
  }

  Future<List<City>> fetchCities() async {
    final res = await _client.get(_uri('/cities'));
    if (res.statusCode != 200) throw Exception('Cities failed: ${res.body}');
    final list = jsonDecode(res.body) as List<dynamic>;
    return list
        .map((e) => City.fromJson(e as Map<String, dynamic>))
        .toList();
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

  Future<List<VastuArticle>> fetchVastuArticles() async {
    final res = await _client.get(_uri('/spiritual/vastu/articles'));
    if (res.statusCode != 200) throw Exception('Vastu articles failed: ${res.body}');
    final list = jsonDecode(res.body) as List<dynamic>;
    return list.map((e) => VastuArticle.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<int>> fetchVastuYears() async {
    final res = await _client.get(_uri('/spiritual/vastu/years'));
    if (res.statusCode != 200) throw Exception('Vastu years failed: ${res.body}');
    final list = jsonDecode(res.body) as List<dynamic>;
    return list.map((e) => e as int).toList();
  }

  Future<VastuDays> fetchVastuDays({
    required String cityId,
    required int year,
  }) async {
    final res = await _client.get(_uri('/spiritual/vastu/days', {
      'city_id': cityId,
      'year': year.toString(),
    }));
    if (res.statusCode != 200) throw Exception('Vastu days failed: ${res.body}');
    return VastuDays.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<List<PanchaPakshiArticle>> fetchPanchaPakshiArticles() async {
    final res = await _client.get(_uri('/spiritual/pancha-pakshi/articles'));
    if (res.statusCode != 200) throw Exception('Pancha Pakshi articles failed: ${res.body}');
    final list = jsonDecode(res.body) as List<dynamic>;
    return list.map((e) => PanchaPakshiArticle.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<PanchaPakshiArticleDetail> fetchPanchaPakshiArticle(int id) async {
    final res = await _client.get(_uri('/spiritual/pancha-pakshi/articles/$id', {
      'city_id': ApiConfig.defaultCityId,
    }));
    if (res.statusCode != 200) throw Exception('Pancha Pakshi article failed: ${res.body}');
    return PanchaPakshiArticleDetail.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<List<PanchaPakshiNakshatra>> fetchPanchaPakshiNakshatras() async {
    final res = await _client.get(_uri('/spiritual/pancha-pakshi/nakshatras'));
    if (res.statusCode != 200) throw Exception('Nakshatras failed: ${res.body}');
    final list = jsonDecode(res.body) as List<dynamic>;
    return list.map((e) => PanchaPakshiNakshatra.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<PanchaPakshiPakshaOption>> fetchPanchaPakshiPakshaOptions() async {
    final res = await _client.get(_uri('/spiritual/pancha-pakshi/paksha-options'));
    if (res.statusCode != 200) throw Exception('Paksha options failed: ${res.body}');
    final list = jsonDecode(res.body) as List<dynamic>;
    return list
        .map((e) => PanchaPakshiPakshaOption.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<int>> fetchPanchaPakshiYears() async {
    final res = await _client.get(_uri('/spiritual/pancha-pakshi/years'));
    if (res.statusCode != 200) throw Exception('Pancha Pakshi years failed: ${res.body}');
    final list = jsonDecode(res.body) as List<dynamic>;
    return list.map((e) => e as int).toList();
  }

  Future<PanchaPakshiResult> fetchPanchaPakshiCalculate({
    required String cityId,
    required int nakshatraIndex,
    required String birthPakshaId,
    required DateTime date,
  }) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final res = await _client.get(_uri('/spiritual/pancha-pakshi/calculate', {
      'city_id': cityId,
      'nakshatra_index': nakshatraIndex.toString(),
      'birth_paksha_id': birthPakshaId,
      'date': dateStr,
    }));
    if (res.statusCode != 200) throw Exception('Pancha Pakshi calculate failed: ${res.body}');
    return PanchaPakshiResult.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
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

  Future<List<JyotishNakshatra>> fetchJyotishNakshatras() async {
    final res = await _client.get(_uri('/spiritual/jyotish/nakshatras'));
    if (res.statusCode != 200) throw Exception('Nakshatras failed: ${res.body}');
    final list = jsonDecode(res.body) as List<dynamic>;
    return list.map((e) => JyotishNakshatra.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<JyotishRashi>> fetchJyotishRashis() async {
    final res = await _client.get(_uri('/spiritual/jyotish/rashis'));
    if (res.statusCode != 200) throw Exception('Rashis failed: ${res.body}');
    final list = jsonDecode(res.body) as List<dynamic>;
    return list.map((e) => JyotishRashi.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<NazhigaiResult> fetchNazhigaiConvert({
    required String cityId,
    required DateTime date,
    int hour = 0,
    int minute = 0,
    bool toNazhigai = true,
    int nazhigai = 1,
    int vinadi = 0,
  }) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final res = await _client.get(_uri('/spiritual/jyotish/nazhigai-convert', {
      'city_id': cityId,
      'date': dateStr,
      'hour': hour.toString(),
      'minute': minute.toString(),
      'to_nazhigai': toNazhigai.toString(),
      'nazhigai': nazhigai.toString(),
      'vinadi': vinadi.toString(),
    }));
    if (res.statusCode != 200) throw Exception('Nazhigai convert failed: ${res.body}');
    return NazhigaiResult.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<ChandrashtamamResult> fetchChandrashtamam({
    required String cityId,
    required int birthRashiIndex,
    required DateTime date,
  }) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final res = await _client.get(_uri('/spiritual/jyotish/chandrashtamam', {
      'city_id': cityId,
      'birth_rashi_index': birthRashiIndex.toString(),
      'date': dateStr,
    }));
    if (res.statusCode != 200) throw Exception('Chandrashtamam failed: ${res.body}');
    return ChandrashtamamResult.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<NumerologyResult> fetchNumerology({
    required String cityId,
    required String name,
    required DateTime date,
  }) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final res = await _client.get(_uri('/spiritual/jyotish/numerology', {
      'city_id': cityId,
      'name': name,
      'date': dateStr,
    }));
    if (res.statusCode != 200) throw Exception('Numerology failed: ${res.body}');
    return NumerologyResult.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<MarriagePoruthamResult> fetchMarriagePorutham({
    required String cityId,
    required DateTime person1Date,
    required int person1Hour,
    required int person1Minute,
    int? person1Nakshatra,
    required DateTime person2Date,
    required int person2Hour,
    required int person2Minute,
    int? person2Nakshatra,
  }) async {
    final query = <String, String>{
      'city_id': cityId,
      'person1_date': DateFormat('yyyy-MM-dd').format(person1Date),
      'person1_hour': person1Hour.toString(),
      'person1_minute': person1Minute.toString(),
      'person2_date': DateFormat('yyyy-MM-dd').format(person2Date),
      'person2_hour': person2Hour.toString(),
      'person2_minute': person2Minute.toString(),
    };
    if (person1Nakshatra != null) query['person1_nakshatra'] = person1Nakshatra.toString();
    if (person2Nakshatra != null) query['person2_nakshatra'] = person2Nakshatra.toString();
    final res = await _client.get(_uri('/spiritual/jyotish/marriage-porutham', query));
    if (res.statusCode != 200) throw Exception('Marriage porutham failed: ${res.body}');
    return MarriagePoruthamResult.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<TarabalamResult> fetchTarabalam({
    required String cityId,
    required int birthNakshatraIndex,
    required DateTime date,
  }) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final res = await _client.get(_uri('/spiritual/jyotish/tarabalam', {
      'city_id': cityId,
      'birth_nakshatra_index': birthNakshatraIndex.toString(),
      'date': dateStr,
    }));
    if (res.statusCode != 200) throw Exception('Tarabalam failed: ${res.body}');
    return TarabalamResult.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<List<PalangalCategory>> fetchPalangalCategories() async {
    final res = await _client.get(_uri('/spiritual/palangal/categories'));
    if (res.statusCode != 200) throw Exception('Palangal categories failed: ${res.body}');
    final list = jsonDecode(res.body) as List<dynamic>;
    return list.map((e) => PalangalCategory.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<PalangalArticle>> fetchPalangalArticles(String categoryId) async {
    final res = await _client.get(_uri('/spiritual/palangal/categories/$categoryId/articles'));
    if (res.statusCode != 200) throw Exception('Palangal articles failed: ${res.body}');
    final list = jsonDecode(res.body) as List<dynamic>;
    return list.map((e) => PalangalArticle.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<PalangalArticleDetail> fetchPalangalArticle(String categoryId, int articleId) async {
    final res = await _client.get(
      _uri('/spiritual/palangal/categories/$categoryId/articles/$articleId'),
    );
    if (res.statusCode != 200) throw Exception('Palangal article failed: ${res.body}');
    return PalangalArticleDetail.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }
}
