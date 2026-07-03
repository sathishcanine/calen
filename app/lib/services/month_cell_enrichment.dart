import 'dart:convert';

import '../models/month_calendar.dart';

/// Derive calendar cell icons from bundled daily panchangam rows (kaalavidya data).
class MonthCellEnrichment {
  MonthCellEnrichment._();

  static const _subaNakshatras = {
    'ரோகிணி',
    'மிருகசீரிடம்',
    'திருவாதிரை',
    'புனர்பூசம்',
    'உத்திரம்',
    'ஹஸ்தம்',
    'சுவாதி',
    'அனுஷம்',
    'மகம்',
    'மூலம்',
    'உத்திராடம்',
    'உத்திரட்டாதி',
    'ரேவதி',
    'சித்திரை',
    'அவிட்டம்',
    'பூசம்',
  };

  static const _badTithi = ['அமாவாசை', 'அஷ்டமி', 'நவமி'];

  static const _kariNaal2026 = {
    '2026-01-15',
    '2026-01-16',
    '2026-01-17',
    '2026-01-25',
    '2026-01-31',
    '2026-02-27',
    '2026-02-28',
    '2026-03-01',
    '2026-03-20',
    '2026-03-29',
    '2026-04-02',
    '2026-04-19',
    '2026-04-28',
    '2026-05-21',
    '2026-05-30',
    '2026-05-31',
    '2026-06-15',
    '2026-06-20',
    '2026-07-18',
    '2026-07-26',
    '2026-08-05',
    '2026-08-19',
    '2026-08-26',
    '2026-09-14',
    '2026-10-03',
    '2026-10-16',
    '2026-10-23',
    '2026-11-17',
    '2026-11-23',
    '2026-11-26',
    '2026-12-03',
    '2026-12-21',
    '2026-12-24',
    '2026-12-26',
  };

  static const _govHoliday2026 = {
    '2026-01-01',
    '2026-01-15',
    '2026-01-16',
    '2026-01-26',
    '2026-02-01',
    '2026-03-19',
    '2026-04-01',
    '2026-04-03',
    '2026-04-14',
    '2026-05-01',
    '2026-05-28',
    '2026-06-26',
    '2026-08-15',
    '2026-08-26',
    '2026-09-14',
    '2026-10-02',
    '2026-10-20',
    '2026-11-08',
    '2026-12-25',
  };

  static MonthCalendar enrich(MonthCalendar month, Map<String, Map<String, Object?>> dailyByDate) {
    final enrichedDays = month.days.map((cell) {
      if (cell.isOtherMonth || cell.gregorianDay == null) return cell;

      final dateKey = _dateKey(month.year, month.month, cell.gregorianDay!);
      final row = dailyByDate[dateKey];
      final icons = row != null ? _iconsFromRow(row) : cell.icons;
      final moon = row != null ? _moonFromRow(row) : cell.moonPhase;

      var highlight = cell.highlightColor;
      if (_govHoliday2026.contains(dateKey)) {
        highlight = 'red';
      } else if (cell.isToday) {
        highlight = 'green';
      }

      return MonthDayCell(
        gregorianDay: cell.gregorianDay,
        tamilDay: cell.tamilDay,
        isSunday: cell.isSunday,
        isToday: cell.isToday,
        isHighlight: cell.isToday || highlight == 'red',
        highlightColor: highlight,
        icons: icons.isNotEmpty ? icons : cell.icons,
        moonPhase: moon ?? cell.moonPhase,
        isOtherMonth: cell.isOtherMonth,
      );
    }).toList();

    return MonthCalendar(
      cityId: month.cityId,
      year: month.year,
      month: month.month,
      monthLabelTa: month.monthLabelTa,
      tamilMonthsTa: month.tamilMonthsTa,
      days: enrichedDays,
      fastingDays: month.fastingDays,
      weddingDays: month.weddingDays,
      otherDays: month.otherDays,
      hinduFestivals: month.hinduFestivals,
      muslimFestivals: month.muslimFestivals,
      christianFestivals: month.christianFestivals,
      governmentHolidays: month.governmentHolidays,
    );
  }

  static List<String> _iconsFromRow(Map<String, Object?> row) {
    final panchangam = _decodeList(row['panchangam_json'] as String?);
    var tithiText = '';
    var nakText = '';
    for (final item in panchangam) {
      final map = item as Map<String, dynamic>;
      if (map['label'] == 'திதி') tithiText = map['value'] as String? ?? '';
      if (map['label'] == 'நட்சத்திரம்') nakText = map['value'] as String? ?? '';
    }

    final banner = row['banner_line_ta'] as String? ?? '';
    final weekday = banner.contains(',') ? banner.split(',').last.trim() : '';

    final icons = <String>[];
    if (_isSubaMuhurtham(tithiText, nakText, row)) icons.add('thaali');

    if (tithiText.contains('அமாவாசை')) {
      icons.add(weekday == 'திங்கள்' ? 'sarva_amavasai' : 'amavasai');
    }
    if (tithiText.contains('பௌர்ணமி')) icons.add('pournami');
    if (tithiText.contains('சஷ்டி')) icons.add('murugan');
    if (tithiText.contains('சதுர்த்தி')) icons.add('ganesha');
    if (tithiText.contains('ஏகாதசி')) icons.add('perumal');
    if (tithiText.contains('திரயோதசி')) icons.add('nandi');
    if (tithiText.contains('சதுர்த்தசி') && tithiText.contains('தேய்பிறை')) icons.add('shiva');
    if (nakText.contains('கிருத்திகை')) icons.add('star');
    if (nakText.contains('உத்திரம்') && !nakText.contains('உத்திராட')) icons.add('thiruvonam');

    return _dedupe(icons);
  }

  static String? _moonFromRow(Map<String, Object?> row) {
    final panchangam = _decodeList(row['panchangam_json'] as String?);
    for (final item in panchangam) {
      final map = item as Map<String, dynamic>;
      if (map['label'] != 'திதி') continue;
      final val = map['value'] as String? ?? '';
      if (val.contains('அமாவாசை')) return 'amavasai';
      if (val.contains('பௌர்ணமி')) return 'pournami';
    }
    return null;
  }

  static bool _isSubaMuhurtham(String tithiText, String nakText, Map<String, Object?> row) {
    final dateKey = row['gregorian_date'] as String? ?? '';
    if (_kariNaal2026.contains(dateKey)) return false;
    if (_badTithi.any((token) => tithiText.contains(token))) return false;
    if (tithiText.contains('சதுர்த்தசி') && tithiText.contains('தேய்பிறை')) return false;
    return _subaNakshatras.any((nak) => nakText.contains(nak));
  }

  static List<dynamic> _decodeList(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    return jsonDecode(raw) as List<dynamic>;
  }

  static List<String> _dedupe(List<String> items) {
    final seen = <String>{};
    final out = <String>[];
    for (final item in items) {
      if (seen.add(item)) out.add(item);
    }
    return out;
  }

  static String _dateKey(int year, int month, int day) {
    return '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
  }
}
