import '../models/daily_calendar.dart';
import '../models/month_calendar.dart';
import 'spiritual_static_bundle.dart';

/// Resolved labels + icons for the daily detail event card.
class DailyEventDetails {
  const DailyEventDetails({
    required this.headerLabels,
    required this.iconIds,
    required this.footerLabels,
  });

  final List<String> headerLabels;
  final List<String> iconIds;
  final List<String> footerLabels;

  bool get isEmpty => headerLabels.isEmpty && footerLabels.isEmpty;
}

/// Build daily event card content from panchangam, vastu, and month festivals.
class DailyEventResolver {
  DailyEventResolver._();

  static DailyEventDetails resolve({
    required DailyCalendar day,
    MonthCalendar? month,
  }) {
    var tithiText = '';
    var nakText = '';
    for (final item in day.panchangam) {
      if (item.label == 'திதி') tithiText = item.value;
      if (item.label == 'நட்சத்திரம்') nakText = item.value;
    }

    final weekday = _weekdayFromBanner(day.bannerLineTa);
    final dateKey = _dateKey(day.gregorianDate);

    final header = <String>[];
    final icons = <String>[];

    if (_isVastuDay(day.gregorianDate)) {
      header.add('வாஸ்து நாள்');
      icons.add('vastu');
    }

    if (tithiText.contains('சதுர்த்தி')) {
      if (tithiText.contains('தேய்பிறை')) {
        header.add('சங்கடஹர சதுர்த்தி');
      } else {
        header.add('விநாயகர் சதுர்த்தி');
      }
      icons.add('ganesha');
    }

    if (_isSubaMuhurtham(tithiText, nakText, dateKey)) {
      header.add('சுபமுகூர்த்தம்');
      if (!icons.contains('thaali')) icons.add('thaali');
    }

    if (tithiText.contains('அமாவாசை')) {
      header.add(weekday == 'திங்கள்' ? 'சர்வ அமாவாசை' : 'அமாவாசை');
      icons.add(weekday == 'திங்கள்' ? 'sarva_amavasai' : 'amavasai');
    } else if (tithiText.contains('பௌர்ணமி')) {
      header.add('பௌர்ணமி');
      icons.add('pournami');
    }

    if (tithiText.contains('சஷ்டி')) {
      header.add('சஷ்டி');
      if (!icons.contains('murugan')) icons.add('murugan');
    }
    if (tithiText.contains('ஏகாதசி')) {
      header.add('ஏகாதசி');
      if (!icons.contains('perumal')) icons.add('perumal');
    }
    if (tithiText.contains('திரயோதசி')) {
      header.add('பிரதோஷம்');
      if (!icons.contains('nandi')) icons.add('nandi');
    }
    if (tithiText.contains('சதுர்த்தசி') && tithiText.contains('தேய்பிறை')) {
      header.add('சிவராத்திரி');
      if (!icons.contains('shiva')) icons.add('shiva');
    }
    if (nakText.contains('கிருத்திகை')) {
      header.add('கிருத்திகை');
      if (!icons.contains('star')) icons.add('star');
    }
    if (nakText.contains('உத்திரம்') && !nakText.contains('உத்திராட')) {
      header.add('திருவோணம்');
      if (!icons.contains('thiruvonam')) icons.add('thiruvonam');
    }

    if (tithiText.contains('தேய்பிறை') &&
        !tithiText.contains('அமாவாசை') &&
        !icons.any((id) => id == 'amavasai' || id == 'sarva_amavasai' || id == 'pournami')) {
      icons.add('crescent');
    }

    final footer = <String>[];
    if (day.eventsTa.trim().isNotEmpty) {
      footer.addAll(
        day.eventsTa.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty),
      );
    }

    if (month != null) {
      final dayNum = day.gregorianDate.day.toString();
      for (final list in [
        month.hinduFestivals,
        month.muslimFestivals,
        month.christianFestivals,
        month.governmentHolidays,
      ]) {
        for (final item in list) {
          if ('${item['day']}' == dayNum) {
            final title = '${item['title']}'.trim();
            if (title.isNotEmpty && !footer.contains(title)) footer.add(title);
          }
        }
      }
    }

    for (final title in _staticFestivals(dateKey)) {
      if (!footer.contains(title)) footer.add(title);
    }

    return DailyEventDetails(
      headerLabels: _dedupe(header),
      iconIds: _orderIcons(icons),
      footerLabels: _dedupe(footer),
    );
  }

  static List<String> _orderIcons(List<String> icons) {
    const order = [
      'ganesha',
      'murugan',
      'perumal',
      'nandi',
      'shiva',
      'star',
      'thiruvonam',
      'thaali',
      'crescent',
      'amavasai',
      'sarva_amavasai',
      'pournami',
      'vastu',
    ];
    final ranked = icons.toSet();
    final out = <String>[];
    for (final id in order) {
      if (ranked.contains(id)) out.add(id);
    }
    for (final id in icons) {
      if (!out.contains(id)) out.add(id);
    }
    return out;
  }

  static bool _isVastuDay(DateTime date) {
    final bundle = SpiritualStaticBundle.instance.data;
    final byYear = bundle['vastu_days_by_year'] as Map<String, dynamic>?;
    if (byYear == null) return false;
    final list = byYear[date.year.toString()] as List<dynamic>? ?? [];
    final key = _dateKey(date);
    return list.any((e) => (e as Map<String, dynamic>)['gregorian_date'] == key);
  }

  static bool _isSubaMuhurtham(String tithiText, String nakText, String dateKey) {
    const kariNaal = {
      '2026-01-15', '2026-01-16', '2026-01-17', '2026-01-25', '2026-01-31',
      '2026-02-27', '2026-02-28', '2026-03-01', '2026-03-20', '2026-03-29',
      '2026-04-02', '2026-04-19', '2026-04-28', '2026-05-21', '2026-05-30',
      '2026-05-31', '2026-06-15', '2026-06-20', '2026-07-18', '2026-07-26',
      '2026-08-05', '2026-08-19', '2026-08-26', '2026-09-14', '2026-10-03',
      '2026-10-16', '2026-10-23', '2026-11-17', '2026-11-23', '2026-11-26',
      '2026-12-03', '2026-12-21', '2026-12-24', '2026-12-26',
    };
    if (kariNaal.contains(dateKey)) return false;
    if (['அமாவாசை', 'அஷ்டமி', 'நவமி'].any(tithiText.contains)) return false;
    if (tithiText.contains('சதுர்த்தசி') && tithiText.contains('தேய்பிறை')) return false;
    const subaNak = {
      'ரோகிணி', 'மிருகசீரிடம்', 'திருவாதிரை', 'புனர்பூசம்', 'உத்திரம்',
      'ஹஸ்தம்', 'சுவாதி', 'அனுஷம்', 'மகம்', 'மூலம்', 'உத்திராடம்',
      'உத்திரட்டாதி', 'ரேவதி', 'சித்திரை', 'அவிட்டம்', 'பூசம்',
    };
    return subaNak.any(nakText.contains);
  }

  static String _weekdayFromBanner(String banner) {
    if (!banner.contains(',')) return '';
    return banner.split(',').last.trim();
  }

  static String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  static List<String> _staticFestivals(String dateKey) {
    const map = {
      '2026-06-03': ['கோவளம் தமீம் அன்சாரி பாஷா உருஸ்'],
      '2026-06-04': ['கார்ப்பஸ் கிறிஸ்தி'],
      '2026-06-17': ['ஹிஜ்ரி புத்தாண்டு'],
      '2026-06-20': ['ஸ்ரீ மாணிக்கவாசகர் குரு பூஜை'],
      '2026-06-22': ['ஆனி உத்திர தரிசனம்'],
      '2026-06-26': ['முஹர்ரம் பண்டிகை'],
      '2026-06-29': ['ஆர்ச் பீட்டர் அன்பல்'],
    };
    return map[dateKey] ?? const [];
  }

  static List<String> _dedupe(List<String> items) {
    final seen = <String>{};
    final out = <String>[];
    for (final item in items) {
      if (item.isEmpty || !seen.add(item)) continue;
      out.add(item);
    }
    return out;
  }
}
