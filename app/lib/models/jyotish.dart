class JyotishNakshatra {
  JyotishNakshatra({required this.index, required this.nameTa});

  final int index;
  final String nameTa;

  factory JyotishNakshatra.fromJson(Map<String, dynamic> json) => JyotishNakshatra(
        index: json['index'] as int,
        nameTa: json['name_ta'] as String,
      );
}

class JyotishRashi {
  JyotishRashi({required this.index, required this.nameTa});

  final int index;
  final String nameTa;

  factory JyotishRashi.fromJson(Map<String, dynamic> json) => JyotishRashi(
        index: json['index'] as int,
        nameTa: json['name_ta'] as String,
      );
}

class NazhigaiResult {
  NazhigaiResult({
    required this.mode,
    required this.segmentTa,
    required this.sunrise,
    required this.sunset,
    required this.dayDurationTa,
    required this.nightDurationTa,
    required this.displayTa,
    this.inputTime,
    this.nazhigai,
    this.vinadi,
    this.vighadiya,
    this.equivalentTime,
  });

  final String mode;
  final String segmentTa;
  final String sunrise;
  final String sunset;
  final String dayDurationTa;
  final String nightDurationTa;
  final String displayTa;
  final String? inputTime;
  final int? nazhigai;
  final int? vinadi;
  final int? vighadiya;
  final String? equivalentTime;

  factory NazhigaiResult.fromJson(Map<String, dynamic> json) => NazhigaiResult(
        mode: json['mode'] as String,
        segmentTa: json['segment_ta'] as String,
        sunrise: json['sunrise'] as String,
        sunset: json['sunset'] as String,
        dayDurationTa: json['day_duration_ta'] as String,
        nightDurationTa: json['night_duration_ta'] as String,
        displayTa: json['display_ta'] as String,
        inputTime: json['input_time'] as String?,
        nazhigai: json['nazhigai'] as int?,
        vinadi: json['vinadi'] as int?,
        vighadiya: json['vighadiya'] as int?,
        equivalentTime: json['equivalent_time'] as String?,
      );
}

class ChandrashtamamPeriod {
  ChandrashtamamPeriod({
    required this.rashiTa,
    required this.timeRange,
    required this.isChandrashtamam,
  });

  final String rashiTa;
  final String timeRange;
  final bool isChandrashtamam;

  factory ChandrashtamamPeriod.fromJson(Map<String, dynamic> json) => ChandrashtamamPeriod(
        rashiTa: json['rashi_ta'] as String,
        timeRange: json['time_range'] as String,
        isChandrashtamam: json['is_chandrashtamam'] as bool,
      );
}

class ChandrashtamamResult {
  ChandrashtamamResult({
    required this.birthRashiTa,
    required this.chandrashtamamRashiTa,
    required this.isActiveNow,
    required this.noteTa,
    required this.periods,
  });

  final String birthRashiTa;
  final String chandrashtamamRashiTa;
  final bool isActiveNow;
  final String noteTa;
  final List<ChandrashtamamPeriod> periods;

  factory ChandrashtamamResult.fromJson(Map<String, dynamic> json) => ChandrashtamamResult(
        birthRashiTa: json['birth_rashi_ta'] as String,
        chandrashtamamRashiTa: json['chandrashtamam_rashi_ta'] as String,
        isActiveNow: json['is_active_now'] as bool,
        noteTa: json['note_ta'] as String,
        periods: (json['periods'] as List<dynamic>)
            .map((e) => ChandrashtamamPeriod.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class NumerologyResult {
  NumerologyResult({
    required this.fullName,
    required this.nameNumber,
    required this.destinyNumber,
    required this.birthNakshatraTa,
    required this.birthRashiTa,
    required this.interpretationTa,
    required this.summaryTa,
  });

  final String fullName;
  final int nameNumber;
  final int destinyNumber;
  final String birthNakshatraTa;
  final String birthRashiTa;
  final String interpretationTa;
  final String summaryTa;

  factory NumerologyResult.fromJson(Map<String, dynamic> json) => NumerologyResult(
        fullName: json['full_name'] as String,
        nameNumber: json['name_number'] as int,
        destinyNumber: json['destiny_number'] as int,
        birthNakshatraTa: json['birth_nakshatra_ta'] as String,
        birthRashiTa: json['birth_rashi_ta'] as String,
        interpretationTa: json['interpretation_ta'] as String,
        summaryTa: json['summary_ta'] as String,
      );
}

class PoruthamFactor {
  PoruthamFactor({required this.nameTa, required this.matched, required this.noteTa});

  final String nameTa;
  final bool matched;
  final String noteTa;

  factory PoruthamFactor.fromJson(Map<String, dynamic> json) => PoruthamFactor(
        nameTa: json['name_ta'] as String,
        matched: json['matched'] as bool,
        noteTa: json['note_ta'] as String,
      );
}

class MarriagePoruthamResult {
  MarriagePoruthamResult({
    required this.person1NakshatraTa,
    required this.person2NakshatraTa,
    required this.person1RashiTa,
    required this.person2RashiTa,
    required this.totalScore,
    required this.maxScore,
    required this.verdictTa,
    required this.factors,
  });

  final String person1NakshatraTa;
  final String person2NakshatraTa;
  final String person1RashiTa;
  final String person2RashiTa;
  final int totalScore;
  final int maxScore;
  final String verdictTa;
  final List<PoruthamFactor> factors;

  factory MarriagePoruthamResult.fromJson(Map<String, dynamic> json) => MarriagePoruthamResult(
        person1NakshatraTa: json['person1_nakshatra_ta'] as String,
        person2NakshatraTa: json['person2_nakshatra_ta'] as String,
        person1RashiTa: json['person1_rashi_ta'] as String,
        person2RashiTa: json['person2_rashi_ta'] as String,
        totalScore: json['total_score'] as int,
        maxScore: json['max_score'] as int,
        verdictTa: json['verdict_ta'] as String,
        factors: (json['factors'] as List<dynamic>)
            .map((e) => PoruthamFactor.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class TarabalamPeriod {
  TarabalamPeriod({
    required this.transitNakshatraTa,
    required this.timeRange,
    this.taraNameTa = '',
  });

  final String transitNakshatraTa;
  final String timeRange;
  final String taraNameTa;

  factory TarabalamPeriod.fromJson(Map<String, dynamic> json) => TarabalamPeriod(
        transitNakshatraTa: json['transit_nakshatra_ta'] as String,
        timeRange: json['time_range'] as String,
        taraNameTa: json['tara_name_ta'] as String? ?? '',
      );
}

class TarabalamResult {
  TarabalamResult({
    required this.birthNakshatraTa,
    required this.noteTa,
    required this.favorablePeriods,
    required this.unfavorablePeriods,
  });

  final String birthNakshatraTa;
  final String noteTa;
  final List<TarabalamPeriod> favorablePeriods;
  final List<TarabalamPeriod> unfavorablePeriods;

  factory TarabalamResult.fromJson(Map<String, dynamic> json) => TarabalamResult(
        birthNakshatraTa: json['birth_nakshatra_ta'] as String,
        noteTa: json['note_ta'] as String,
        favorablePeriods: (json['favorable_periods'] as List<dynamic>)
            .map((e) => TarabalamPeriod.fromJson(e as Map<String, dynamic>))
            .toList(),
        unfavorablePeriods: (json['unfavorable_periods'] as List<dynamic>)
            .map((e) => TarabalamPeriod.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
