import 'dart:convert';

import 'package:intl/intl.dart';

import '../models/daily_calendar.dart';
import '../models/month_calendar.dart';

List<dynamic> _decodeList(String? raw) {
  if (raw == null || raw.isEmpty) return [];
  return jsonDecode(raw) as List<dynamic>;
}

Map<String, dynamic> _decodeMap(String? raw) {
  if (raw == null || raw.isEmpty) return {};
  final decoded = jsonDecode(raw);
  return decoded is Map<String, dynamic> ? decoded : {};
}

/// Map a `daily_calendars` SQLite row to API-shaped JSON for [DailyCalendar].
Map<String, dynamic> dailyRowToJson(Map<String, Object?> row) {
  final gdate = row['gregorian_date'] as String;
  return {
    'city_id': row['city_id'],
    'gregorian_date': gdate,
    'month_label_ta': row['month_label_ta'] ?? '',
    'gregorian_display': row['gregorian_display'] ?? '',
    'subtitle_line1_ta': row['subtitle_line1_ta'] ?? '',
    'subtitle_line2_ta': row['subtitle_line2_ta'] ?? '',
    'banner_line_ta': row['banner_line_ta'] ?? '',
    'events_ta': row['events_ta'] ?? '',
    'nalla_neram': _decodeList(row['nalla_neram_json'] as String?),
    'gowri_nalla_neram': _decodeList(row['gowri_nalla_neram_json'] as String?),
    'panchangam': _decodeList(row['panchangam_json'] as String?),
    'inauspicious': _decodeList(row['inauspicious_json'] as String?),
    'shoolam_ta': row['shoolam_ta'] ?? '',
    'pariharam_ta': row['pariharam_ta'] ?? '',
    'lagnam_ta': row['lagnam_ta'] ?? '',
    'rasi_chart': _decodeList(row['rasi_chart_json'] as String?),
    'rasi_center_ta': row['rasi_center_ta'] ?? '',
    'horoscope': _decodeList(row['horoscope_json'] as String?),
    'quote_ta': row['quote_ta'] ?? '',
    'birthdays_ta': row['birthdays_ta'] ?? '',
    'note_ta': row['note_ta'] ?? '',
  };
}

DailyCalendar dailyFromRow(Map<String, Object?> row) =>
    DailyCalendar.fromJson(dailyRowToJson(row));

HomeSummary homeFromRow(Map<String, Object?> row) => HomeSummary.fromJson({
      'banner_line_ta': row['banner_line_ta'] ?? '',
      'gregorian_display': row['gregorian_display'] ?? '',
      'gregorian_date': row['gregorian_date'],
    });

Map<String, dynamic> monthRowToJson(Map<String, Object?> row) => {
      'city_id': row['city_id'],
      'year': row['year'],
      'month': row['month'],
      'month_label_ta': row['month_label_ta'] ?? '',
      'tamil_months_ta': row['tamil_months_ta'] ?? '',
      'days': _decodeList(row['days_json'] as String?),
      'fasting_days': _decodeList(row['fasting_days_json'] as String?),
      'wedding_days': _decodeList(row['wedding_days_json'] as String?),
      'other_days': _decodeList(row['other_days_json'] as String?),
      'hindu_festivals': _decodeList(row['hindu_festivals_json'] as String?),
      'muslim_festivals': _decodeList(row['muslim_festivals_json'] as String?),
      'christian_festivals': _decodeList(row['christian_festivals_json'] as String?),
      'government_holidays': _decodeList(row['government_holidays_json'] as String?),
    };

MonthCalendar monthFromRow(Map<String, Object?> row) =>
    MonthCalendar.fromJson(monthRowToJson(row));

String formatSqlDate(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

String weekdayTaFromLabel(String monthLabelTa) {
  if (!monthLabelTa.contains(' - ')) return '';
  return monthLabelTa.split(' - ').last.trim();
}

Map<String, dynamic> gowriJsonFromRow(Map<String, Object?> row) =>
    _decodeMap(row['gowri_panchangam_json'] as String?);

Map<String, dynamic> horaJsonFromRow(Map<String, Object?> row) =>
    _decodeMap(row['hora_json'] as String?);

List<dynamic> inauspiciousJsonFromRow(Map<String, Object?> row) =>
    _decodeList(row['inauspicious_json'] as String?);

String inauspiciousSlotTime(List<dynamic> slots, String name) {
  for (final slot in slots) {
    final map = slot as Map<String, dynamic>;
    if (map['name'] == name) return map['time'] as String? ?? '';
  }
  return '';
}

DateTime weekSunday(DateTime target) =>
    target.subtract(Duration(days: target.weekday % 7));

String stripPrefix(String value, String prefix) {
  if (value.startsWith(prefix)) return value.substring(prefix.length).trim();
  return value;
}
