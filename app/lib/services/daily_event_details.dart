import '../data/fasting_observance_dates.dart';
import '../data/suba_muhurtham_dates.dart';
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

    void addMarker(String label, String iconId) {
      if (!header.contains(label)) header.add(label);
      if (!icons.contains(iconId)) icons.add(iconId);
    }

    if (_isVastuDay(day.gregorianDate)) {
      addMarker('வாஸ்து நாள்', 'vastu');
    }

    if (_isSubaMuhurtham(tithiText, nakText, dateKey)) {
      addMarker('சுப முகூர்த்த நாள்', 'thaali');
      if (!icons.contains('home_good')) icons.add('home_good');
      if (!icons.contains('vehicle_good')) icons.add('vehicle_good');
    }

    // Curated timing-correct dates (Nithra-style) — do not OR with raw tithi text
    // or eve+sunrise double-marking returns.
    final sunTithi = sunriseTithiText(tithiText);
    final ama = isAmavasaiDate(dateKey);
    final pou = isPournamiDate(dateKey);
    if (ama) {
      addMarker(
        weekday == 'திங்கள்' ? 'சர்வ அமாவாசை' : 'அமாவாசை',
        weekday == 'திங்கள்' ? 'sarva_amavasai' : 'amavasai',
      );
    } else if (pou) {
      addMarker('பௌர்ணமி', 'pournami');
    }

    if (isSashtiDate(dateKey)) {
      addMarker('சஷ்டி', 'murugan');
    }
    if (isEkadasiDate(dateKey)) {
      addMarker('ஏகாதசி', 'perumal');
    }
    if (sunTithi.contains('அஷ்டமி')) {
      addMarker('அஷ்டமி', 'ashtami');
    }
    if (sunTithi.contains('நவமி')) {
      addMarker('நவமி', 'navami');
    }
    if (sunTithi.contains('துவாதசி')) {
      addMarker('துவாதசி', 'dwadashi');
    }
    if (sunTithi.contains('பிரதமை')) {
      addMarker('பிரதமை', 'prathamai');
    }
    if (isPradoshamDate(dateKey)) {
      addMarker('பிரதோஷம்', 'nandi');
    }
    if (isSivaratriDate(dateKey)) {
      addMarker('சிவராத்திரி', 'shiva');
    }
    if (isSankataharaDate(dateKey)) {
      addMarker('சங்கடஹர சதுர்த்தி', 'sankatahara');
    } else if (isChaturthiDate(dateKey)) {
      addMarker('சதுர்த்தி', 'ganesha');
    }
    if (isKiruthigaiDate(dateKey)) {
      addMarker('கிருத்திகை', 'krittigai');
    }
    if (isThiruvonamDate(dateKey)) {
      addMarker('திருவோணம்', 'thiruvonam');
    }

    if (sunTithi.contains('தேய்பிறை') &&
        !ama &&
        !icons.any(
          (id) =>
              id == 'amavasai' || id == 'sarva_amavasai' || id == 'pournami',
        )) {
      icons.add('crescent');
    }

    final footer = <String>[];
    void addFooter(String title) {
      final clean = title.trim();
      if (clean.isNotEmpty && !footer.contains(clean)) footer.add(clean);
      final icon = _festivalIcon(clean);
      if (icon != null && !icons.contains(icon)) icons.add(icon);
    }

    if (day.eventsTa.trim().isNotEmpty) {
      for (final title in day.eventsTa.split(',')) {
        addFooter(title);
      }
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
            addFooter(title);
          }
        }
      }
    }

    for (final title in _staticFestivals(dateKey)) {
      addFooter(title);
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
      'home_good',
      'vehicle_good',
      'land_good',
      'business_good',
      'jewel_good',
      'education_good',
      'amman',
      'crescent',
      'amavasai',
      'sarva_amavasai',
      'pournami',
      'ashtami',
      'navami',
      'dwadashi',
      'prathamai',
      'krittigai',
      'tamil_month',
      'festival',
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

  static String? _festivalIcon(String text) {
    if (text.isEmpty) return null;
    if (text.contains('திருமண') || text.contains('முகூர்த்த')) return 'thaali';
    if (text.contains('கிரகப்பிரவேச') || text.contains('வீடு')) {
      return 'home_good';
    }
    if (text.contains('வாகனம்')) return 'vehicle_good';
    if (text.contains('நிலம்')) return 'land_good';
    if (text.contains('தொழில்')) return 'business_good';
    if (text.contains('நகை')) return 'jewel_good';
    if (text.contains('கல்வி')) return 'education_good';
    if (text.contains('அம்மன்')) return 'amman';
    if (text.contains('முருக')) return 'murugan';
    if (text.contains('பெருமாள்') || text.contains('விஷ்ணு')) return 'perumal';
    if (text.contains('சிவ') || text.contains('ருத்ர')) return 'shiva';
    if (text.contains('தமிழ் மாத') || text.contains('மாத பிறப்பு')) {
      return 'tamil_month';
    }
    if (text.contains('பண்டிகை') || text.contains('திருவிழா')) {
      return 'festival';
    }
    return null;
  }

  static bool _isVastuDay(DateTime date) {
    final bundle = SpiritualStaticBundle.instance.data;
    final byYear = bundle['vastu_days_by_year'] as Map<String, dynamic>?;
    if (byYear == null) return false;
    final list = byYear[date.year.toString()] as List<dynamic>? ?? [];
    final key = _dateKey(date);
    return list.any(
      (e) => (e as Map<String, dynamic>)['gregorian_date'] == key,
    );
  }

  static bool _isSubaMuhurtham(
    String tithiText,
    String nakText,
    String dateKey,
  ) {
    return isSubaMuhurthamDate(dateKey);
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
