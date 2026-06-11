class GowriSlot {
  GowriSlot({
    required this.time,
    required this.name,
    required this.auspicious,
  });

  factory GowriSlot.fromJson(Map<String, dynamic> json) => GowriSlot(
        time: json['time'] as String? ?? '',
        name: json['name'] as String? ?? '',
        auspicious: json['auspicious'] as bool? ?? true,
      );

  final String time;
  final String name;
  final bool auspicious;
}

class GowriSection {
  GowriSection({
    required this.period,
    required this.slots,
  });

  factory GowriSection.fromJson(Map<String, dynamic> json) => GowriSection(
        period: json['period'] as String? ?? '',
        slots: (json['slots'] as List<dynamic>? ?? [])
            .map((e) => GowriSlot.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  final String period;
  final List<GowriSlot> slots;
}

class GowriWeekDay {
  GowriWeekDay({
    required this.weekdayTa,
    required this.gregorianDate,
    required this.sections,
  });

  factory GowriWeekDay.fromJson(Map<String, dynamic> json) => GowriWeekDay(
        weekdayTa: json['weekday_ta'] as String? ?? '',
        gregorianDate: DateTime.parse(json['gregorian_date'] as String),
        sections: (json['sections'] as List<dynamic>? ?? [])
            .map((e) => GowriSection.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  final String weekdayTa;
  final DateTime gregorianDate;
  final List<GowriSection> sections;
}

class GowriWeek {
  GowriWeek({
    required this.cityId,
    required this.weekStart,
    required this.days,
  });

  factory GowriWeek.fromJson(Map<String, dynamic> json) => GowriWeek(
        cityId: json['city_id'] as String? ?? '',
        weekStart: DateTime.parse(json['week_start'] as String),
        days: (json['days'] as List<dynamic>? ?? [])
            .map((e) => GowriWeekDay.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  final String cityId;
  final DateTime weekStart;
  final List<GowriWeekDay> days;
}
