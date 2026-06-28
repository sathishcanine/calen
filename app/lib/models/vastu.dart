class VastuArticle {
  VastuArticle({required this.id, required this.titleTa});

  factory VastuArticle.fromJson(Map<String, dynamic> json) => VastuArticle(
        id: json['id'] as int? ?? 0,
        titleTa: json['title_ta'] as String? ?? '',
      );

  final int id;
  final String titleTa;
}

class VastuDay {
  VastuDay({
    required this.gregorianDate,
    required this.labelLine1Ta,
    required this.timeLineTa,
  });

  factory VastuDay.fromJson(Map<String, dynamic> json) => VastuDay(
        gregorianDate: DateTime.parse(json['gregorian_date'] as String),
        labelLine1Ta: json['label_line1_ta'] as String? ?? '',
        timeLineTa: json['time_line_ta'] as String? ?? '',
      );

  final DateTime gregorianDate;
  final String labelLine1Ta;
  final String timeLineTa;
}

class VastuDays {
  VastuDays({
    required this.cityId,
    required this.year,
    required this.days,
  });

  factory VastuDays.fromJson(Map<String, dynamic> json) => VastuDays(
        cityId: json['city_id'] as String? ?? '',
        year: json['year'] as int? ?? 2026,
        days: (json['days'] as List<dynamic>? ?? [])
            .map((e) => VastuDay.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  final String cityId;
  final int year;
  final List<VastuDay> days;
}
