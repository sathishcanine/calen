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
}
