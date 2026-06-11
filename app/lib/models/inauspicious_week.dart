class InauspiciousWeekDay {
  InauspiciousWeekDay({
    required this.weekdayTa,
    required this.gregorianDate,
    required this.rahuKalam,
    required this.gulikaiKalam,
    required this.yamagandam,
    required this.shoolam,
    required this.pariharam,
  });

  factory InauspiciousWeekDay.fromJson(Map<String, dynamic> json) => InauspiciousWeekDay(
        weekdayTa: json['weekday_ta'] as String? ?? '',
        gregorianDate: DateTime.parse(json['gregorian_date'] as String),
        rahuKalam: json['rahu_kalam'] as String? ?? '',
        gulikaiKalam: json['gulikai_kalam'] as String? ?? '',
        yamagandam: json['yamagandam'] as String? ?? '',
        shoolam: json['shoolam'] as String? ?? '',
        pariharam: json['pariharam'] as String? ?? '',
      );

  final String weekdayTa;
  final DateTime gregorianDate;
  final String rahuKalam;
  final String gulikaiKalam;
  final String yamagandam;
  final String shoolam;
  final String pariharam;
}

class InauspiciousWeek {
  InauspiciousWeek({
    required this.cityId,
    required this.weekStart,
    required this.days,
  });

  factory InauspiciousWeek.fromJson(Map<String, dynamic> json) => InauspiciousWeek(
        cityId: json['city_id'] as String? ?? '',
        weekStart: DateTime.parse(json['week_start'] as String),
        days: (json['days'] as List<dynamic>? ?? [])
            .map((e) => InauspiciousWeekDay.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  final String cityId;
  final DateTime weekStart;
  final List<InauspiciousWeekDay> days;
}
