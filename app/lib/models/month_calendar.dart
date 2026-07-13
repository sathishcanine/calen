import '../data/fasting_observance_dates.dart';
import '../data/suba_muhurtham_dates.dart';
import '../data/tamil_solar_month.dart';

class MonthDayCell {
  MonthDayCell({
    this.gregorianDay,
    this.tamilDay,
    this.isSunday = false,
    this.isToday = false,
    this.isHighlight = false,
    this.highlightColor,
    this.icons = const [],
    this.moonPhase,
    this.isOtherMonth = false,
  });

  factory MonthDayCell.fromJson(Map<String, dynamic> json) => MonthDayCell(
        gregorianDay: json['gregorian_day'] as int?,
        tamilDay: json['tamil_day'] as int?,
        isSunday: json['is_sunday'] as bool? ?? false,
        isToday: json['is_today'] as bool? ?? false,
        isHighlight: json['is_highlight'] as bool? ?? false,
        highlightColor: json['highlight_color'] as String?,
        icons: (json['icons'] as List<dynamic>? ?? []).cast<String>(),
        moonPhase: json['moon_phase'] as String?,
        isOtherMonth: json['is_other_month'] as bool? ?? false,
      );

  final int? gregorianDay;
  final int? tamilDay;
  final bool isSunday;
  final bool isToday;
  final bool isHighlight;
  final String? highlightColor;
  final List<String> icons;
  final String? moonPhase;
  final bool isOtherMonth;
}

class MonthListItem {
  MonthListItem({this.icon, required this.titleTa, required this.datesTa});

  factory MonthListItem.fromJson(Map<String, dynamic> json) => MonthListItem(
        icon: json['icon'] as String?,
        titleTa: json['title_ta'] as String? ?? '',
        datesTa: json['dates_ta'] as String? ?? '',
      );

  final String? icon;
  final String titleTa;
  final String datesTa;
}

class MonthCalendar {
  MonthCalendar({
    required this.cityId,
    required this.year,
    required this.month,
    required this.monthLabelTa,
    required this.tamilMonthsTa,
    required this.days,
    required this.fastingDays,
    required this.weddingDays,
    required this.otherDays,
    required this.hinduFestivals,
    required this.muslimFestivals,
    required this.christianFestivals,
    required this.governmentHolidays,
  });

  factory MonthCalendar.fromJson(Map<String, dynamic> json) => MonthCalendar(
        cityId: json['city_id'] as String? ?? '',
        year: json['year'] as int? ?? 0,
        month: json['month'] as int? ?? 0,
        monthLabelTa: json['month_label_ta'] as String? ?? '',
        tamilMonthsTa: json['tamil_months_ta'] as String? ?? '',
        days: (json['days'] as List<dynamic>? ?? [])
            .map((e) => MonthDayCell.fromJson(e as Map<String, dynamic>))
            .toList(),
        fastingDays: (json['fasting_days'] as List<dynamic>? ?? [])
            .map((e) => MonthListItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        weddingDays: (json['wedding_days'] as List<dynamic>? ?? []).cast<String>(),
        otherDays: (json['other_days'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>(),
        hinduFestivals: (json['hindu_festivals'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>(),
        muslimFestivals: (json['muslim_festivals'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>(),
        christianFestivals: (json['christian_festivals'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>(),
        governmentHolidays: (json['government_holidays'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>(),
      );

  final String cityId;
  final int year;
  final int month;
  final String monthLabelTa;
  final String tamilMonthsTa;
  final List<MonthDayCell> days;
  final List<MonthListItem> fastingDays;
  final List<String> weddingDays;
  final List<Map<String, dynamic>> otherDays;
  final List<Map<String, dynamic>> hinduFestivals;
  final List<Map<String, dynamic>> muslimFestivals;
  final List<Map<String, dynamic>> christianFestivals;
  final List<Map<String, dynamic>> governmentHolidays;

  /// Recompute [MonthDayCell.isToday] from the device clock (stored JSON is stale).
  MonthCalendar withLiveToday([DateTime? now]) {
    final today = now ?? DateTime.now();
    final todayDay =
        year == today.year && month == today.month ? today.day : null;

    return MonthCalendar(
      cityId: cityId,
      year: year,
      month: month,
      monthLabelTa: monthLabelTa,
      tamilMonthsTa: tamilMonthsTa,
      days: days.map((cell) {
        final isToday = todayDay != null &&
            !cell.isOtherMonth &&
            cell.gregorianDay == todayDay;
        final isHoliday = cell.highlightColor == 'red';
        return MonthDayCell(
          gregorianDay: cell.gregorianDay,
          tamilDay: cell.tamilDay,
          isSunday: cell.isSunday,
          isToday: isToday,
          isHighlight: isToday || isHoliday,
          highlightColor: isHoliday
              ? 'red'
              : isToday
                  ? 'green'
                  : null,
          icons: cell.icons,
          moonPhase: cell.moonPhase,
          isOtherMonth: cell.isOtherMonth,
        );
      }).toList(),
      fastingDays: fastingDays,
      weddingDays: weddingDays,
      otherDays: otherDays,
      hinduFestivals: hinduFestivals,
      muslimFestivals: muslimFestivals,
      christianFestivals: christianFestivals,
      governmentHolidays: governmentHolidays,
    );
  }

  /// Keep thaali only on curated publisher muhurtham dates (Nithra-style).
  MonthCalendar withLiveMuhurtham() {
    String keyFor(MonthDayCell cell) {
      final d = cell.gregorianDay;
      if (d == null || cell.isOtherMonth) return '';
      return '$year-${month.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}';
    }

    return MonthCalendar(
      cityId: cityId,
      year: year,
      month: month,
      monthLabelTa: monthLabelTa,
      tamilMonthsTa: tamilMonthsTa,
      days: days.map((cell) {
        final key = keyFor(cell);
        final keepThaali = key.isNotEmpty && isSubaMuhurthamDate(key);
        final icons = keepThaali
            ? (cell.icons.contains('thaali')
                ? cell.icons
                : ['thaali', ...cell.icons])
            : cell.icons.where((id) => id != 'thaali').toList();
        return MonthDayCell(
          gregorianDay: cell.gregorianDay,
          tamilDay: cell.tamilDay,
          isSunday: cell.isSunday,
          isToday: cell.isToday,
          isHighlight: cell.isHighlight,
          highlightColor: cell.highlightColor,
          icons: icons,
          moonPhase: cell.moonPhase,
          isOtherMonth: cell.isOtherMonth,
        );
      }).toList(),
      fastingDays: fastingDays,
      weddingDays: weddingDayLabelsForMonth(year, month),
      otherDays: otherDays,
      hinduFestivals: hinduFestivals,
      muslimFestivals: muslimFestivals,
      christianFestivals: christianFestivals,
      governmentHolidays: governmentHolidays,
    );
  }

  /// Nithra-style viratham icons + fasting list (fixes sunrise-only off-by-one).
  MonthCalendar withLiveFastingObservances() {
    String keyFor(MonthDayCell cell) {
      final d = cell.gregorianDay;
      if (d == null || cell.isOtherMonth) return '';
      return '$year-${month.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}';
    }

    const weekdayTa = [
      'திங்கள்',
      'செவ்வாய்',
      'புதன்',
      'வியாழன்',
      'வெள்ளி',
      'சனி',
      'ஞாயிறு',
    ];
    String labelForKey(String key) {
      final day = int.parse(key.substring(8));
      final dt = DateTime(year, month, day);
      return '$day ${weekdayTa[dt.weekday - 1]}';
    }

    final prefix = '$year-${month.toString().padLeft(2, '0')}-';
    List<String> labels(Set<String> dates) =>
        dates.where((k) => k.startsWith(prefix)).map(labelForKey).toList();

    final fasting = <MonthListItem>[
      if (labels(amavasai2026).isNotEmpty)
        MonthListItem(
          icon: 'amavasai',
          titleTa: 'அமாவாசை',
          datesTa: labels(amavasai2026).join(', '),
        ),
      if (labels(pournami2026).isNotEmpty)
        MonthListItem(
          icon: 'pournami',
          titleTa: 'பௌர்ணமி',
          datesTa: labels(pournami2026).join(', '),
        ),
      if (labels(kiruthigai2026).isNotEmpty)
        MonthListItem(
          icon: 'star',
          titleTa: 'கிருத்திகை',
          datesTa: labels(kiruthigai2026).join(', '),
        ),
      if (labels(thiruvonam2026).isNotEmpty)
        MonthListItem(
          icon: 'thiruvonam',
          titleTa: 'திருவோணம்',
          datesTa: labels(thiruvonam2026).join(', '),
        ),
      if (labels(ekadasi2026).isNotEmpty)
        MonthListItem(
          icon: 'perumal',
          titleTa: 'ஏகாதசி',
          datesTa: labels(ekadasi2026).join(', '),
        ),
      if (labels(sashti2026).isNotEmpty)
        MonthListItem(
          icon: 'murugan',
          titleTa: 'சஷ்டி',
          datesTa: labels(sashti2026).join(', '),
        ),
      if (labels(sankatahara2026).isNotEmpty)
        MonthListItem(
          icon: 'sankatahara',
          titleTa: 'சங்கடஹர சதுர்த்தி',
          datesTa: labels(sankatahara2026).join(', '),
        ),
      if (labels(sivaratri2026).isNotEmpty)
        MonthListItem(
          icon: 'shiva',
          titleTa: 'சிவராத்திரி',
          datesTa: labels(sivaratri2026).join(', '),
        ),
      if (labels(pradosham2026).isNotEmpty)
        MonthListItem(
          icon: 'nandi',
          titleTa: 'பிரதோஷம்',
          datesTa: labels(pradosham2026).join(', '),
        ),
      if (labels(chaturthi2026).isNotEmpty)
        MonthListItem(
          icon: 'ganesha',
          titleTa: 'சதுர்த்தி',
          datesTa: labels(chaturthi2026).join(', '),
        ),
    ];

    const stripIds = {
      'amavasai',
      'sarva_amavasai',
      'pournami',
      'murugan',
      'perumal',
      'nandi',
      'shiva',
      'ganesha',
      'sankatahara',
      'star',
      'thiruvonam',
    };

    return MonthCalendar(
      cityId: cityId,
      year: year,
      month: month,
      monthLabelTa: monthLabelTa,
      tamilMonthsTa: tamilMonthsTa,
      days: days.map((cell) {
        final key = keyFor(cell);
        final kept = cell.icons.where((id) => !stripIds.contains(id)).toList();
        final add = <String>[];
        String? moon;
        if (key.isNotEmpty) {
          if (isAmavasaiDate(key)) {
            final dt = DateTime(year, month, int.parse(key.substring(8)));
            add.add(dt.weekday == DateTime.monday ? 'sarva_amavasai' : 'amavasai');
            moon = 'amavasai';
          } else if (isPournamiDate(key)) {
            add.add('pournami');
            moon = 'pournami';
          }
          if (isSashtiDate(key)) add.add('murugan');
          if (isChaturthiDate(key) || isSankataharaDate(key)) add.add('ganesha');
          if (isEkadasiDate(key)) add.add('perumal');
          if (isPradoshamDate(key)) add.add('nandi');
          if (isSivaratriDate(key)) add.add('shiva');
          if (isKiruthigaiDate(key)) add.add('star');
          if (isThiruvonamDate(key)) add.add('thiruvonam');
        }
        return MonthDayCell(
          gregorianDay: cell.gregorianDay,
          tamilDay: cell.tamilDay,
          isSunday: cell.isSunday,
          isToday: cell.isToday,
          isHighlight: cell.isHighlight,
          highlightColor: cell.highlightColor,
          icons: [...kept.where((id) => id == 'thaali'), ...add, ...kept.where((id) => id != 'thaali')],
          moonPhase: moon,
          isOtherMonth: cell.isOtherMonth,
        );
      }).toList(),
      fastingDays: fasting,
      weddingDays: weddingDays,
      otherDays: otherDays,
      hinduFestivals: hinduFestivals,
      muslimFestivals: muslimFestivals,
      christianFestivals: christianFestivals,
      governmentHolidays: governmentHolidays,
    );
  }

  /// Alias kept for older call sites.
  MonthCalendar withLiveMoonPhases() => withLiveFastingObservances();

  /// Fix corner Tamil solar day numbers (Nithra-style சௌர மாதம்).
  MonthCalendar withLiveTamilSolarDays() {
    return MonthCalendar(
      cityId: cityId,
      year: year,
      month: month,
      monthLabelTa: monthLabelTa,
      tamilMonthsTa: tamilMonthsRangeForGregorianMonth(year, month),
      days: days.map((cell) {
        final d = cell.gregorianDay;
        if (d == null) return cell;
        final dt = cell.isOtherMonth
            ? (d > 15
                ? DateTime(year, month - 1, d)
                : DateTime(year, month + 1, d))
            : DateTime(year, month, d);
        final solar = tamilSolarDayFor(dt);
        return MonthDayCell(
          gregorianDay: cell.gregorianDay,
          tamilDay: solar?.day ?? cell.tamilDay,
          isSunday: cell.isSunday,
          isToday: cell.isToday,
          isHighlight: cell.isHighlight,
          highlightColor: cell.highlightColor,
          icons: cell.icons,
          moonPhase: cell.moonPhase,
          isOtherMonth: cell.isOtherMonth,
        );
      }).toList(),
      fastingDays: fastingDays,
      weddingDays: weddingDays,
      otherDays: otherDays,
      hinduFestivals: hinduFestivals,
      muslimFestivals: muslimFestivals,
      christianFestivals: christianFestivals,
      governmentHolidays: governmentHolidays,
    );
  }
}
