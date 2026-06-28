class PanchaPakshiArticle {
  PanchaPakshiArticle({
    required this.id,
    required this.titleTa,
    required this.kind,
  });

  factory PanchaPakshiArticle.fromJson(Map<String, dynamic> json) => PanchaPakshiArticle(
        id: json['id'] as int,
        titleTa: json['title_ta'] as String? ?? '',
        kind: json['kind'] as String? ?? '',
      );

  final int id;
  final String titleTa;
  final String kind;
}

class PanchaPakshiNakshatra {
  PanchaPakshiNakshatra({required this.index, required this.nameTa});

  factory PanchaPakshiNakshatra.fromJson(Map<String, dynamic> json) => PanchaPakshiNakshatra(
        index: json['index'] as int,
        nameTa: json['name_ta'] as String? ?? '',
      );

  final int index;
  final String nameTa;
}

class PanchaPakshiPakshaOption {
  PanchaPakshiPakshaOption({required this.id, required this.labelTa});

  factory PanchaPakshiPakshaOption.fromJson(Map<String, dynamic> json) =>
      PanchaPakshiPakshaOption(
        id: json['id'] as String? ?? '',
        labelTa: json['label_ta'] as String? ?? '',
      );

  final String id;
  final String labelTa;
}

class PanchaPakshiSlot {
  PanchaPakshiSlot({
    required this.time,
    required this.activityTa,
    this.strengthTa = '',
    this.strengthPct = 0,
  });

  factory PanchaPakshiSlot.fromJson(Map<String, dynamic> json) => PanchaPakshiSlot(
        time: json['time'] as String? ?? '',
        activityTa: json['activity_ta'] as String? ?? '',
        strengthTa: json['strength_ta'] as String? ?? '',
        strengthPct: json['strength_pct'] as int? ?? 0,
      );

  final String time;
  final String activityTa;
  final String strengthTa;
  final int strengthPct;
}

class PanchaPakshiSection {
  PanchaPakshiSection({required this.periodTa, required this.slots});

  factory PanchaPakshiSection.fromJson(Map<String, dynamic> json) => PanchaPakshiSection(
        periodTa: json['period_ta'] as String? ?? '',
        slots: (json['slots'] as List<dynamic>? ?? [])
            .map((e) => PanchaPakshiSlot.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  final String periodTa;
  final List<PanchaPakshiSlot> slots;
}

class PanchaPakshiResult {
  PanchaPakshiResult({
    required this.nakshatraTa,
    required this.birthPakshaTa,
    required this.birdTa,
    required this.gregorianDate,
    required this.weekdayTa,
    required this.observationPakshaTa,
    required this.sections,
  });

  factory PanchaPakshiResult.fromJson(Map<String, dynamic> json) => PanchaPakshiResult(
        nakshatraTa: json['nakshatra_ta'] as String? ?? '',
        birthPakshaTa: json['birth_paksha_ta'] as String? ?? '',
        birdTa: json['bird_ta'] as String? ?? '',
        gregorianDate: DateTime.parse(json['gregorian_date'] as String),
        weekdayTa: json['weekday_ta'] as String? ?? '',
        observationPakshaTa: json['observation_paksha_ta'] as String? ?? '',
        sections: (json['sections'] as List<dynamic>? ?? [])
            .map((e) => PanchaPakshiSection.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  final String nakshatraTa;
  final String birthPakshaTa;
  final String birdTa;
  final DateTime gregorianDate;
  final String weekdayTa;
  final String observationPakshaTa;
  final List<PanchaPakshiSection> sections;
}

class PanchaPakshiArticleDetail {
  PanchaPakshiArticleDetail({
    required this.id,
    required this.titleTa,
    required this.kind,
    required this.content,
  });

  factory PanchaPakshiArticleDetail.fromJson(Map<String, dynamic> json) =>
      PanchaPakshiArticleDetail(
        id: json['id'] as int,
        titleTa: json['title_ta'] as String? ?? '',
        kind: json['kind'] as String? ?? '',
        content: json['content'] as Map<String, dynamic>? ?? {},
      );

  final int id;
  final String titleTa;
  final String kind;
  final Map<String, dynamic> content;
}
