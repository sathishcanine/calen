class IndruContent {
  const IndruContent({
    required this.gregorianDate,
    required this.birthdayTa,
    required this.birthdayDetailTa,
    required this.historicEventTa,
    required this.historicEventDetailTa,
    required this.factTa,
    required this.quoteTa,
    required this.quoteAuthorTa,
    required this.kuralNumber,
    required this.kuralTa,
    required this.kuralMeaningTa,
  });

  factory IndruContent.fromJson(Map<String, dynamic> json) {
    return IndruContent(
      gregorianDate: DateTime.parse(json['gregorian_date'] as String),
      birthdayTa: json['birthday_ta'] as String? ?? '',
      birthdayDetailTa: json['birthday_detail_ta'] as String? ?? '',
      historicEventTa: json['historic_event_ta'] as String? ?? '',
      historicEventDetailTa: json['historic_event_detail_ta'] as String? ?? '',
      factTa: json['fact_ta'] as String? ?? '',
      quoteTa: json['quote_ta'] as String? ?? '',
      quoteAuthorTa: json['quote_author_ta'] as String? ?? '',
      kuralNumber: json['kural_number'] as int? ?? 1,
      kuralTa: json['kural_ta'] as String? ?? '',
      kuralMeaningTa: json['kural_meaning_ta'] as String? ?? '',
    );
  }

  static final empty = IndruContent(
    gregorianDate: DateTime(1970),
    birthdayTa: '',
    birthdayDetailTa: '',
    historicEventTa: '',
    historicEventDetailTa: '',
    factTa: '',
    quoteTa: '',
    quoteAuthorTa: '',
    kuralNumber: 1,
    kuralTa: '',
    kuralMeaningTa: '',
  );

  final DateTime gregorianDate;
  final String birthdayTa;
  final String birthdayDetailTa;
  final String historicEventTa;
  final String historicEventDetailTa;
  final String factTa;
  final String quoteTa;
  final String quoteAuthorTa;
  final int kuralNumber;
  final String kuralTa;
  final String kuralMeaningTa;

  bool get hasContent =>
      birthdayTa.isNotEmpty ||
      historicEventTa.isNotEmpty ||
      factTa.isNotEmpty ||
      quoteTa.isNotEmpty ||
      kuralTa.isNotEmpty;
}
