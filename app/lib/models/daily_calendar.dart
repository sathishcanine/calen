import '../data/tamil_solar_month.dart';

class TimeSlot {
  TimeSlot({required this.period, required this.time});

  factory TimeSlot.fromJson(Map<String, dynamic> json) => TimeSlot(
        period: json['period'] as String? ?? '',
        time: json['time'] as String? ?? '',
      );

  final String period;
  final String time;
}

class PanchangamItem {
  PanchangamItem({required this.label, required this.value});

  factory PanchangamItem.fromJson(Map<String, dynamic> json) => PanchangamItem(
        label: json['label'] as String? ?? '',
        value: json['value'] as String? ?? '',
      );

  final String label;
  final String value;
}

class InauspiciousSlot {
  InauspiciousSlot({required this.name, required this.time});

  factory InauspiciousSlot.fromJson(Map<String, dynamic> json) => InauspiciousSlot(
        name: json['name'] as String? ?? '',
        time: json['time'] as String? ?? '',
      );

  final String name;
  final String time;
}

class HoroscopeItem {
  HoroscopeItem({required this.sign, required this.prediction});

  factory HoroscopeItem.fromJson(Map<String, dynamic> json) => HoroscopeItem(
        sign: json['sign'] as String? ?? '',
        prediction: json['prediction'] as String? ?? '',
      );

  final String sign;
  final String prediction;
}

class DailyCalendar {
  DailyCalendar({
    required this.cityId,
    required this.gregorianDate,
    required this.monthLabelTa,
    required this.gregorianDisplay,
    required this.subtitleLine1Ta,
    required this.subtitleLine2Ta,
    required this.bannerLineTa,
    required this.eventsTa,
    required this.nallaNeram,
    required this.gowriNallaNeram,
    required this.panchangam,
    required this.inauspicious,
    required this.shoolamTa,
    required this.pariharamTa,
    required this.lagnamTa,
    required this.rasiChart,
    required this.rasiCenterTa,
    required this.horoscope,
    required this.quoteTa,
    required this.birthdaysTa,
    required this.noteTa,
  });

  /// Fix banner/subtitle Tamil solar day (DB mixed lunar masa + sun degree).
  DailyCalendar withLiveTamilSolarBanner() {
    final solar = tamilSolarDayFor(gregorianDate);
    if (solar == null) return this;
    final weekday = _weekdayFromBannerLine(bannerLineTa);
    final banner = weekday.isEmpty
        ? '${solar.monthTa} - ${solar.day}'
        : '${solar.monthTa} - ${solar.day}, $weekday';
    final subtitle2 = _rewriteSubtitleSolarDay(subtitleLine2Ta, solar);
    return DailyCalendar(
      cityId: cityId,
      gregorianDate: gregorianDate,
      monthLabelTa: monthLabelTa,
      gregorianDisplay: gregorianDisplay,
      subtitleLine1Ta: subtitleLine1Ta,
      subtitleLine2Ta: subtitle2,
      bannerLineTa: banner,
      eventsTa: eventsTa,
      nallaNeram: nallaNeram,
      gowriNallaNeram: gowriNallaNeram,
      panchangam: panchangam,
      inauspicious: inauspicious,
      shoolamTa: shoolamTa,
      pariharamTa: pariharamTa,
      lagnamTa: lagnamTa,
      rasiChart: rasiChart,
      rasiCenterTa: rasiCenterTa,
      horoscope: horoscope,
      quoteTa: quoteTa,
      birthdaysTa: birthdaysTa,
      noteTa: noteTa,
    );
  }

  factory DailyCalendar.fromJson(Map<String, dynamic> json) => DailyCalendar(
        cityId: json['city_id'] as String? ?? '',
        gregorianDate: DateTime.parse(json['gregorian_date'] as String),
        monthLabelTa: json['month_label_ta'] as String? ?? '',
        gregorianDisplay: json['gregorian_display'] as String? ?? '',
        subtitleLine1Ta: json['subtitle_line1_ta'] as String? ?? '',
        subtitleLine2Ta: json['subtitle_line2_ta'] as String? ?? '',
        bannerLineTa: json['banner_line_ta'] as String? ?? '',
        eventsTa: json['events_ta'] as String? ?? '',
        nallaNeram: (json['nalla_neram'] as List<dynamic>? ?? [])
            .map((e) => TimeSlot.fromJson(e as Map<String, dynamic>))
            .toList(),
        gowriNallaNeram: (json['gowri_nalla_neram'] as List<dynamic>? ?? [])
            .map((e) => TimeSlot.fromJson(e as Map<String, dynamic>))
            .toList(),
        panchangam: (json['panchangam'] as List<dynamic>? ?? [])
            .map((e) => PanchangamItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        inauspicious: (json['inauspicious'] as List<dynamic>? ?? [])
            .map((e) => InauspiciousSlot.fromJson(e as Map<String, dynamic>))
            .toList(),
        shoolamTa: json['shoolam_ta'] as String? ?? '',
        pariharamTa: json['pariharam_ta'] as String? ?? '',
        lagnamTa: json['lagnam_ta'] as String? ?? '',
        rasiChart: (json['rasi_chart'] as List<dynamic>? ?? [])
            .map((e) => e as String?)
            .toList(),
        rasiCenterTa: json['rasi_center_ta'] as String? ?? '',
        horoscope: (json['horoscope'] as List<dynamic>? ?? [])
            .map((e) => HoroscopeItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        quoteTa: json['quote_ta'] as String? ?? '',
        birthdaysTa: json['birthdays_ta'] as String? ?? '',
        noteTa: json['note_ta'] as String? ?? '',
      );

  final String cityId;
  final DateTime gregorianDate;
  final String monthLabelTa;
  final String gregorianDisplay;
  final String subtitleLine1Ta;
  final String subtitleLine2Ta;
  final String bannerLineTa;
  final String eventsTa;
  final List<TimeSlot> nallaNeram;
  final List<TimeSlot> gowriNallaNeram;
  final List<PanchangamItem> panchangam;
  final List<InauspiciousSlot> inauspicious;
  final String shoolamTa;
  final String pariharamTa;
  final String lagnamTa;
  final List<String?> rasiChart;
  final String rasiCenterTa;
  final List<HoroscopeItem> horoscope;
  final String quoteTa;
  final String birthdaysTa;
  final String noteTa;
}

class HomeSummary {
  HomeSummary({
    required this.bannerLineTa,
    required this.gregorianDisplay,
    required this.gregorianDate,
  });

  factory HomeSummary.fromJson(Map<String, dynamic> json) => HomeSummary(
        bannerLineTa: json['banner_line_ta'] as String? ?? '',
        gregorianDisplay: json['gregorian_display'] as String? ?? '',
        gregorianDate: DateTime.parse(json['gregorian_date'] as String),
      );

  final String bannerLineTa;
  final String gregorianDisplay;
  final DateTime gregorianDate;

  HomeSummary withLiveTamilSolarBanner() {
    final solar = tamilSolarDayFor(gregorianDate);
    if (solar == null) return this;
    final weekday = _weekdayFromBannerLine(bannerLineTa);
    final banner = weekday.isEmpty
        ? '${solar.monthTa} - ${solar.day}'
        : '${solar.monthTa} - ${solar.day}, $weekday';
    return HomeSummary(
      bannerLineTa: banner,
      gregorianDisplay: gregorianDisplay,
      gregorianDate: gregorianDate,
    );
  }
}

String _weekdayFromBannerLine(String banner) {
  if (!banner.contains(',')) return '';
  return banner.split(',').last.trim();
}

String _rewriteSubtitleSolarDay(String subtitle, TamilSolarDay solar) {
  // e.g. "பராபவ - ஆனி - 27" → "பராபவ - ஆனி - 29"
  final parts = subtitle.split(' - ').map((e) => e.trim()).toList();
  if (parts.length >= 3) {
    parts[parts.length - 2] = solar.monthTa;
    parts[parts.length - 1] = '${solar.day}';
    return parts.join(' - ');
  }
  if (parts.length == 2) {
    return '${parts.first} - ${solar.monthTa} - ${solar.day}';
  }
  return subtitle.isEmpty
      ? '${solar.monthTa} - ${solar.day}'
      : subtitle;
}
