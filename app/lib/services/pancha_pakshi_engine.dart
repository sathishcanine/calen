import 'package:flutter/services.dart';

import '../models/pancha_pakshi.dart';

/// On-device Pancha Pakshi calculator (CSV rules + sunrise/sunset from Gowri data).
class PanchaPakshiEngine {
  PanchaPakshiEngine._();

  static final PanchaPakshiEngine instance = PanchaPakshiEngine._();

  static const _assetPath = 'assets/data/pancha_pakshi_db.csv';

  static const birdsTa = ['வல்லூறு', 'ஆந்தை', 'காகம்', 'கோழி', 'மயில்'];
  static const activitiesTa = ['அரசு', 'ஊண்', 'நடை', 'துயில்', 'சாவு'];
  static const strengthTa = [
    '100% பலம் கொண்டது',
    '80% பலம் கொண்டது',
    '50% பலம் கொண்டது',
    '25% பலம் கொண்டது',
    '0% பலம் கொண்டது',
  ];
  static const strengthPct = [100, 80, 50, 25, 0];
  static const weekdaysTa = ['ஞாயிறு', 'திங்கள்', 'செவ்வாய்', 'புதன்', 'வியாழன்', 'வெள்ளி', 'சனி'];

  static const nakshatraNamesTa = [
    'அஸ்வினி', 'பரணி', 'கிருத்திகை', 'ரோகிணி', 'மிருகசீரிடம்',
    'திருவாதிரை', 'புனர்பூசம்', 'பூசம்', 'ஆயில்யம்', 'மகம்',
    'பூரம்', 'உத்திரம்', 'அஸ்தம்', 'சித்திரை', 'சுவாதி',
    'விசாகம்', 'அனுஷம்', 'கேட்டை', 'மூலம்', 'பூராடம்',
    'உத்திராடம்', 'திருவோணம்', 'அவிட்டம்', 'சதயம்',
    'பூரட்டாதி', 'உத்திரட்டாதி', 'ரேவதி',
  ];

  static const _birthBirdByNakshatra = [
    [0, 4], [0, 4], [0, 4], [0, 4], [0, 4],
    [1, 3], [1, 3], [1, 3], [1, 3], [1, 3], [1, 3],
    [2, 2], [2, 2], [2, 2], [2, 2], [2, 2],
    [3, 1], [3, 1], [3, 1], [3, 1], [3, 1],
    [4, 0], [4, 0], [4, 0], [4, 0], [4, 0], [4, 0],
  ];

  late List<({int w, int p, int dn, int b, int act})> _rows;
  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;
    _rows = [];
    final raw = await rootBundle.loadString(_assetPath);
    final lines = raw.split('\n');
    for (var i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      final parts = line.split(',');
      if (parts.length < 5) continue;
      try {
        _rows.add((
          w: double.parse(parts[0]).toInt(),
          p: double.parse(parts[1]).toInt(),
          dn: double.parse(parts[2]).toInt(),
          b: double.parse(parts[3]).toInt(),
          act: double.parse(parts[4]).toInt(),
        ));
      } catch (_) {
        continue;
      }
    }
    _loaded = true;
  }

  int _birthPakshaIndex(String birthPakshaId) {
    if (birthPakshaId == 'valarpirai' || birthPakshaId == 'pournami') return 0;
    return 1;
  }

  int birthBirdIndex(int nakshatraIndex, String birthPakshaId) {
    final pair = _birthBirdByNakshatra[nakshatraIndex];
    return _birthPakshaIndex(birthPakshaId) == 0 ? pair[0] : pair[1];
  }

  int weekdayIndex(DateTime date) => date.weekday % 7;

  int observationPakshaIndex(String tithiValue) =>
      tithiValue.contains('தேய்பிறை') ? 1 : 0;

  List<int> _mainActivities(int weekday, int paksha, int bird, int daynight) {
    final filtered = _rows
        .where((r) => r.w == weekday && r.p == paksha && r.b == bird && r.dn == daynight)
        .map((r) => r.act)
        .toList();
    final result = <int>[];
    for (var i = 0; i < filtered.length && i < 25; i += 5) {
      result.add(filtered[i]);
    }
    while (result.length < 5) {
      result.add(0);
    }
    return result.take(5).toList();
  }

  double _parseHm(String token) {
    final cleaned = token.trim().replaceAll(' ', '');
    final parts = cleaned.split('.');
    if (parts.length != 2) return 0;
    return int.parse(parts[0]) + int.parse(parts[1]) / 60.0;
  }

  ({double sunrise, double sunset}) sunTimesFromGowri(Map<String, dynamic> gowri) {
    final sections = (gowri['sections'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    double sunrise = 6.0;
    double sunset = 18.0;

    for (final section in sections) {
      final period = section['period'] as String? ?? '';
      final slots = (section['slots'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
      if (slots.isEmpty) continue;
      final first = slots.first['time'] as String? ?? '';
      final last = slots.last['time'] as String? ?? '';
      if (period == 'காலை' && first.contains(' - ')) {
        sunrise = _parseHm(first.split(' - ').first);
      }
      if (period == 'மாலை' && last.contains(' - ')) {
        sunset = _parseHm(last.split(' - ').last);
      }
    }
    return (sunrise: sunrise, sunset: sunset);
  }

  String _fmtHm(double hours) {
    final h = hours.floor() % 24;
    final m = ((hours - hours.floor()) * 60).round();
    return '${h.toString().padLeft(2, '0')}.${m.toString().padLeft(2, '0')}';
  }

  String _fmtRange(double start, double end) => '${_fmtHm(start)} - ${_fmtHm(end)}';

  List<({double start, double end})> _slotTimes(double sunrise, double sunset, bool isNight) {
    final start = isNight ? sunset : sunrise;
    final end = isNight ? sunrise + 24 : sunset;
    final span = (end - start) / 5;
    return List.generate(5, (i) => (start: start + span * i, end: start + span * (i + 1)));
  }

  List<PanchaPakshiSlot> _sectionSlots({
    required int weekday,
    required int paksha,
    required int bird,
    required bool isNight,
    required double sunrise,
    required double sunset,
  }) {
    final acts = _mainActivities(weekday, paksha, bird, isNight ? 1 : 0);
    final times = _slotTimes(sunrise, sunset, isNight);
    return List.generate(5, (i) {
      final act = acts[i];
      return PanchaPakshiSlot(
        time: _fmtRange(times[i].start, times[i].end),
        activityTa: activitiesTa[act],
        strengthTa: strengthTa[act],
        strengthPct: strengthPct[act],
      );
    });
  }

  PanchaPakshiResult calculate({
    required int nakshatraIndex,
    required String birthPakshaId,
    required DateTime date,
    required Map<String, dynamic> gowriJson,
    required String tithiValue,
    required String weekdayTa,
  }) {
    final bird = birthBirdIndex(nakshatraIndex, birthPakshaId);
    final paksha = observationPakshaIndex(tithiValue);
    final wdi = weekdayIndex(date);
    final sun = sunTimesFromGowri(gowriJson);

    final birthPakshaTa = birthPakshaId == 'valarpirai'
        ? 'வளர்பிறை'
        : birthPakshaId == 'theypirai'
            ? 'தேய்பிறை'
            : birthPakshaId == 'pournami'
                ? 'பௌர்ணமி'
                : 'அமாவாசை';

    final daySlots = _sectionSlots(
      weekday: wdi,
      paksha: paksha,
      bird: bird,
      isNight: false,
      sunrise: sun.sunrise,
      sunset: sun.sunset,
    );
    final nightSlots = _sectionSlots(
      weekday: wdi,
      paksha: paksha,
      bird: bird,
      isNight: true,
      sunrise: sun.sunrise,
      sunset: sun.sunset,
    );

    return PanchaPakshiResult(
      nakshatraTa: nakshatraNamesTa[nakshatraIndex],
      birthPakshaTa: birthPakshaTa,
      birdTa: birdsTa[bird],
      gregorianDate: date,
      weekdayTa: weekdayTa.isNotEmpty ? weekdayTa : weekdaysTa[wdi],
      observationPakshaTa: paksha == 0 ? 'வளர்பிறை' : 'தேய்பிறை',
      sections: [
        PanchaPakshiSection(
          periodTa: 'பகல்பொழுது (காலை 06.01 AM முதல் மாலை 06.00 PM வரை)',
          slots: daySlots,
        ),
        PanchaPakshiSection(
          periodTa: 'இரவுப்பொழுது (மாலை 06.01 PM முதல் காலை 06.00 AM வரை)',
          slots: nightSlots,
        ),
      ],
    );
  }
}
