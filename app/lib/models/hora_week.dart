class HoraSlot {
  HoraSlot({
    required this.time,
    required this.planet,
    required this.auspicious,
  });

  factory HoraSlot.fromJson(Map<String, dynamic> json) => HoraSlot(
        time: json['time'] as String? ?? '',
        planet: json['planet'] as String? ?? '',
        auspicious: json['auspicious'] as bool? ?? true,
      );

  final String time;
  final String planet;
  final bool auspicious;
}

class HoraSection {
  HoraSection({
    required this.period,
    required this.slots,
  });

  factory HoraSection.fromJson(Map<String, dynamic> json) => HoraSection(
        period: json['period'] as String? ?? '',
        slots: (json['slots'] as List<dynamic>? ?? [])
            .map((e) => HoraSlot.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  final String period;
  final List<HoraSlot> slots;
}

class HoraWeekDay {
  HoraWeekDay({
    required this.weekdayTa,
    required this.gregorianDate,
    required this.sections,
  });

  factory HoraWeekDay.fromJson(Map<String, dynamic> json) => HoraWeekDay(
        weekdayTa: json['weekday_ta'] as String? ?? '',
        gregorianDate: DateTime.parse(json['gregorian_date'] as String),
        sections: (json['sections'] as List<dynamic>? ?? [])
            .map((e) => HoraSection.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  final String weekdayTa;
  final DateTime gregorianDate;
  final List<HoraSection> sections;
}

class HoraWeek {
  HoraWeek({
    required this.cityId,
    required this.weekStart,
    required this.days,
  });

  factory HoraWeek.fromJson(Map<String, dynamic> json) => HoraWeek(
        cityId: json['city_id'] as String? ?? '',
        weekStart: DateTime.parse(json['week_start'] as String),
        days: (json['days'] as List<dynamic>? ?? [])
            .map((e) => HoraWeekDay.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  final String cityId;
  final DateTime weekStart;
  final List<HoraWeekDay> days;
}
