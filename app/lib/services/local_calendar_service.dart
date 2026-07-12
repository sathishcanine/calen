import 'dart:convert';

import '../config/api_config.dart';
import '../models/daily_calendar.dart';
import '../models/gowri_week.dart';
import '../models/hora_week.dart';
import '../models/inauspicious_week.dart';
import '../models/month_calendar.dart';
import '../models/jyotish.dart';
import '../models/palangal.dart';
import '../models/pancha_pakshi.dart';
import '../models/vastu.dart';
import 'local_calendar_mapper.dart';
import 'local_database.dart';
import 'month_cell_enrichment.dart';
import 'pancha_pakshi_engine.dart';
import 'spiritual_static_bundle.dart';

/// Offline data access — mirrors API responses from bundled SQLite + JSON.
class LocalCalendarService {
  LocalCalendarService({String? cityId}) : _cityId = cityId ?? ApiConfig.defaultCityId;

  final String _cityId;

  Future<Map<String, Object?>?> _dailyRow(DateTime date) async {
    final rows = await LocalDatabase.instance.db.query(
      'daily_calendars',
      where: 'city_id = ? AND gregorian_date = ?',
      whereArgs: [_cityId, formatSqlDate(date)],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first;
  }

  Future<HomeSummary> fetchHome({DateTime? date}) async {
    var target = date ?? DateTime.now();
    var row = await _dailyRow(target);
    if (row == null && date == null) {
      final now = DateTime.now();
      final day = now.day.clamp(1, 28);
      target = DateTime(2026, now.month, day);
      row = await _dailyRow(target);
    }
    if (row == null) {
      throw Exception('No offline data for ${formatSqlDate(target)} (2026 Tamil calendar only)');
    }
    return homeFromRow(row);
  }

  Future<DailyCalendar> fetchDay(DateTime date) async {
    final row = await _dailyRow(date);
    if (row == null) {
      throw Exception('No offline data for ${formatSqlDate(date)}');
    }
    return dailyFromRow(row);
  }

  Future<MonthCalendar> fetchMonth(int year, int month) async {
    final rows = await LocalDatabase.instance.db.query(
      'month_calendars',
      where: 'city_id = ? AND year = ? AND month = ?',
      whereArgs: [_cityId, year, month],
      limit: 1,
    );
    if (rows.isEmpty) {
      throw Exception('No offline month data for $year-$month');
    }
    final monthData = monthFromRow(rows.first);

    final lastDay = DateTime(year, month + 1, 0).day;
    final start = formatSqlDate(DateTime(year, month, 1));
    final end = formatSqlDate(DateTime(year, month, lastDay));
    final dailyRows = await LocalDatabase.instance.db.query(
      'daily_calendars',
      where: 'city_id = ? AND gregorian_date >= ? AND gregorian_date <= ?',
      whereArgs: [_cityId, start, end],
    );
    final byDate = {for (final row in dailyRows) row['gregorian_date'] as String: row};

    return MonthCellEnrichment.enrich(monthData, byDate);
  }

  Future<InauspiciousWeek> fetchInauspiciousWeek(DateTime date) async {
    final sunday = weekSunday(date);
    final days = <InauspiciousWeekDay>[];

    for (var i = 0; i < 7; i++) {
      final d = sunday.add(Duration(days: i));
      final row = await _dailyRow(d);
      if (row == null) continue;
      final inauspicious = inauspiciousJsonFromRow(row);
      days.add(InauspiciousWeekDay(
        weekdayTa: weekdayTaFromLabel(row['month_label_ta'] as String? ?? ''),
        gregorianDate: d,
        rahuKalam: inauspiciousSlotTime(inauspicious, 'இராகு'),
        gulikaiKalam: inauspiciousSlotTime(inauspicious, 'குளிகை'),
        yamagandam: inauspiciousSlotTime(inauspicious, 'எமகண்டம்'),
        shoolam: stripPrefix(row['shoolam_ta'] as String? ?? '', 'சூலம் - '),
        pariharam: stripPrefix(row['pariharam_ta'] as String? ?? '', 'பரிகாரம் - '),
      ));
    }

    return InauspiciousWeek(
      cityId: _cityId,
      weekStart: sunday,
      days: days,
    );
  }

  Future<GowriWeek> fetchGowriWeek(DateTime date) async {
    final sunday = weekSunday(date);
    final days = <GowriWeekDay>[];

    for (var i = 0; i < 7; i++) {
      final d = sunday.add(Duration(days: i));
      final row = await _dailyRow(d);
      if (row == null) continue;
      final gowri = gowriJsonFromRow(row);
      final sections = (gowri['sections'] as List<dynamic>? ?? [])
          .map((s) => GowriSection.fromJson(s as Map<String, dynamic>))
          .toList();
      days.add(GowriWeekDay(
        weekdayTa: weekdayTaFromLabel(row['month_label_ta'] as String? ?? ''),
        gregorianDate: d,
        sections: sections,
      ));
    }

    return GowriWeek(cityId: _cityId, weekStart: sunday, days: days);
  }

  Future<HoraWeek> fetchHoraWeek(DateTime date) async {
    final sunday = weekSunday(date);
    final days = <HoraWeekDay>[];

    for (var i = 0; i < 7; i++) {
      final d = sunday.add(Duration(days: i));
      final row = await _dailyRow(d);
      if (row == null) continue;
      final hora = horaJsonFromRow(row);
      final sections = (hora['sections'] as List<dynamic>? ?? [])
          .map((s) => HoraSection.fromJson(s as Map<String, dynamic>))
          .toList();
      days.add(HoraWeekDay(
        weekdayTa: weekdayTaFromLabel(row['month_label_ta'] as String? ?? ''),
        gregorianDate: d,
        sections: sections,
      ));
    }

    return HoraWeek(cityId: _cityId, weekStart: sunday, days: days);
  }

  Future<List<VastuArticle>> fetchVastuArticles() async {
    final list = SpiritualStaticBundle.instance.data['vastu_articles'] as List<dynamic>;
    return list.map((e) => VastuArticle.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<int>> fetchVastuYears() async {
    final list = SpiritualStaticBundle.instance.data['vastu_years'] as List<dynamic>;
    return list.cast<int>();
  }

  Future<VastuDays> fetchVastuDays(int year) async {
    final byYear = SpiritualStaticBundle.instance.data['vastu_days_by_year'] as Map<String, dynamic>;
    final days = (byYear[year.toString()] as List<dynamic>? ?? [])
        .map((e) => VastuDay.fromJson(e as Map<String, dynamic>))
        .toList();
    return VastuDays(cityId: _cityId, year: year, days: days);
  }

  Future<List<PanchaPakshiArticle>> fetchPanchaPakshiArticles() async {
    final list = SpiritualStaticBundle.instance.data['pancha_pakshi_articles'] as List<dynamic>;
    return list.map((e) => PanchaPakshiArticle.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<PanchaPakshiArticleDetail> fetchPanchaPakshiArticle(int id) async {
    final details =
        SpiritualStaticBundle.instance.data['pancha_pakshi_article_details'] as Map<String, dynamic>;
    final raw = details[id.toString()] as Map<String, dynamic>?;
    if (raw == null) throw Exception('Article $id not found offline');
    return PanchaPakshiArticleDetail.fromJson(raw);
  }

  Future<List<PanchaPakshiNakshatra>> fetchPanchaPakshiNakshatras() async {
    final list = SpiritualStaticBundle.instance.data['pancha_pakshi_nakshatras'] as List<dynamic>;
    return list.map((e) => PanchaPakshiNakshatra.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<PanchaPakshiPakshaOption>> fetchPanchaPakshiPakshaOptions() async {
    final list =
        SpiritualStaticBundle.instance.data['pancha_pakshi_paksha_options'] as List<dynamic>;
    return list
        .map((e) => PanchaPakshiPakshaOption.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<int>> fetchPanchaPakshiYears() async => [2026];

  Future<PanchaPakshiResult> fetchPanchaPakshiCalculate({
    required int nakshatraIndex,
    required String birthPakshaId,
    required DateTime date,
  }) async {
    final row = await _dailyRow(date);
    if (row == null) throw Exception('No offline data for ${formatSqlDate(date)}');

    final panchangam = jsonDecode(row['panchangam_json'] as String? ?? '[]') as List<dynamic>;
    var tithiValue = '';
    for (final item in panchangam) {
      final map = item as Map<String, dynamic>;
      if (map['label'] == 'திதி') tithiValue = map['value'] as String? ?? '';
    }

    return PanchaPakshiEngine.instance.calculate(
      nakshatraIndex: nakshatraIndex,
      birthPakshaId: birthPakshaId,
      date: date,
      gowriJson: gowriJsonFromRow(row),
      tithiValue: tithiValue,
      weekdayTa: weekdayTaFromLabel(row['month_label_ta'] as String? ?? ''),
    );
  }

  Future<List<JyotishNakshatra>> fetchJyotishNakshatras() async {
    final list = SpiritualStaticBundle.instance.data['jyotish_nakshatras'] as List<dynamic>?;
    if (list == null) throw Exception('ஆஃப்லைன்: ஜோதிட கணக்கீடு API தேவை');
    return list.map((e) => JyotishNakshatra.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<JyotishRashi>> fetchJyotishRashis() async {
    final list = SpiritualStaticBundle.instance.data['jyotish_rashis'] as List<dynamic>?;
    if (list == null) throw Exception('ஆஃப்லைன்: ஜோதிட கணக்கீடு API தேவை');
    return list.map((e) => JyotishRashi.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<NazhigaiResult> fetchNazhigaiConvert({
    required DateTime date,
    int hour = 0,
    int minute = 0,
    bool toNazhigai = true,
    int nazhigai = 1,
    int vinadi = 0,
  }) async {
    throw Exception('ஆஃப்லைன்: நாழிகை மாற்றி ஆன்லைன் API தேவை');
  }

  Future<ChandrashtamamResult> fetchChandrashtamam({
    required int birthRashiIndex,
    required DateTime date,
  }) async {
    throw Exception('ஆஃப்லைன்: சந்திராஷ்டமம் கணக்கீடு ஆன்லைன் API தேவை');
  }

  Future<NumerologyResult> fetchNumerology({
    required String name,
    required DateTime date,
  }) async {
    throw Exception('ஆஃப்லைன்: எண்கணிதம் ஆன்லைன் API தேவை');
  }

  Future<MarriagePoruthamResult> fetchMarriagePorutham({
    required DateTime person1Date,
    required int person1Hour,
    required int person1Minute,
    int? person1Nakshatra,
    required DateTime person2Date,
    required int person2Hour,
    required int person2Minute,
    int? person2Nakshatra,
  }) async {
    throw Exception('ஆஃப்லைன்: திருமண பொருத்தம் ஆன்லைன் API தேவை');
  }

  Future<TarabalamResult> fetchTarabalam({
    required int birthNakshatraIndex,
    required DateTime date,
  }) async {
    throw Exception('ஆஃப்லைன்: தாரா பலன் ஆன்லைன் API தேவை');
  }

  Future<List<PalangalCategory>> fetchPalangalCategories() async {
    final list = SpiritualStaticBundle.instance.data['palangal_categories'] as List<dynamic>?;
    if (list == null || list.isEmpty) return [];
    return list.map((e) => PalangalCategory.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<PalangalArticle>> fetchPalangalArticles(String categoryId) async {
    final byCat = SpiritualStaticBundle.instance.data['palangal_articles_by_category'] as Map<String, dynamic>;
    final list = byCat[categoryId] as List<dynamic>? ?? [];
    return list.map((e) => PalangalArticle.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<PalangalArticleDetail> fetchPalangalArticle(String categoryId, int articleId) async {
    final details = SpiritualStaticBundle.instance.data['palangal_article_details'] as Map<String, dynamic>;
    final raw = details['$categoryId-$articleId'] as Map<String, dynamic>?;
    if (raw == null) throw Exception('Article not found offline');
    return PalangalArticleDetail.fromJson(raw);
  }
}
