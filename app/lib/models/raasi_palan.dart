import 'package:flutter/painting.dart';

class RaasiPalanContent {
  const RaasiPalanContent({
    required this.period,
    required this.signIndex,
    required this.signTa,
    this.periodLabel = '',
    this.generalTa = '',
    this.grahamSancharamTa = '',
    this.nakshatraPalanTa = '',
    this.specialTa = '',
    this.cautionsTa = '',
  });

  final String period;
  final int signIndex;
  final String signTa;
  final String periodLabel;
  final String generalTa;
  final String grahamSancharamTa;
  final String nakshatraPalanTa;
  final String specialTa;
  final String cautionsTa;

  bool get isYearly => period == 'yearly';

  bool get hasAnyContent {
    if (isYearly) {
      return grahamSancharamTa.trim().isNotEmpty ||
          generalTa.trim().isNotEmpty ||
          nakshatraPalanTa.trim().isNotEmpty ||
          specialTa.trim().isNotEmpty ||
          cautionsTa.trim().isNotEmpty;
    }
    return generalTa.trim().isNotEmpty;
  }

  /// Split text into paragraphs (blank-line separated).
  static List<String> paragraphsOf(String raw) {
    return raw
        .split(RegExp(r'\n\s*\n'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  /// Parse `#bold#` markers into TextSpans (markers removed, inner text bold).
  static List<InlineSpan> richSpans(
    String raw, {
    required TextStyle base,
    TextStyle? bold,
  }) {
    final boldStyle = bold ??
        base.copyWith(fontWeight: FontWeight.bold);
    final spans = <InlineSpan>[];
    final regex = RegExp(r'#([^#]+)#');
    var start = 0;
    for (final match in regex.allMatches(raw)) {
      if (match.start > start) {
        spans.add(TextSpan(text: raw.substring(start, match.start), style: base));
      }
      spans.add(TextSpan(text: match.group(1), style: boldStyle));
      start = match.end;
    }
    if (start < raw.length) {
      spans.add(TextSpan(text: raw.substring(start), style: base));
    }
    if (spans.isEmpty) {
      spans.add(TextSpan(text: raw, style: base));
    }
    return spans;
  }

  /// Share text: strip `#` markers, keep inner words.
  static String plainForShare(String raw) {
    return raw.replaceAllMapped(RegExp(r'#([^#]+)#'), (m) => m.group(1)!);
  }

  factory RaasiPalanContent.fromJson(Map<String, dynamic> json) {
    return RaasiPalanContent(
      period: json['period'] as String? ?? '',
      signIndex: json['sign_index'] as int? ?? 0,
      signTa: json['sign_ta'] as String? ?? '',
      periodLabel: json['period_label'] as String? ?? '',
      generalTa: json['general_ta'] as String? ?? '',
      grahamSancharamTa: json['graham_sancharam_ta'] as String? ?? '',
      nakshatraPalanTa: json['nakshatra_palan_ta'] as String? ?? '',
      specialTa: json['special_ta'] as String? ?? '',
      cautionsTa: json['cautions_ta'] as String? ?? '',
    );
  }

  static const empty = RaasiPalanContent(
    period: '',
    signIndex: 0,
    signTa: '',
  );
}
