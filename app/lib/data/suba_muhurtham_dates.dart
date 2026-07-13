/// Publisher-style சுப முகூர்த்த நாட்கள் for 2026 (திருமணம் / சுபகாரியங்கள்).
///
/// Source alignment: Samayam / OneIndia / typical Tamil almanac monthly grids
/// (e.g. Nithra). NOT every “good nakshatra” sunrise day.
const subaMuhurtham2026 = {
  '2026-01-28',
  '2026-02-06',
  '2026-02-08',
  '2026-02-13',
  '2026-02-15',
  '2026-02-16',
  '2026-02-20',
  '2026-03-05',
  '2026-03-06',
  '2026-03-08',
  '2026-03-15',
  '2026-03-16',
  '2026-03-25',
  '2026-04-06',
  '2026-04-12',
  '2026-04-13',
  '2026-04-16',
  '2026-04-20',
  '2026-04-23',
  '2026-04-30',
  '2026-05-08',
  '2026-05-13',
  '2026-05-14',
  '2026-05-18',
  '2026-05-28',
  '2026-05-29',
  '2026-06-04',
  '2026-06-07',
  '2026-06-17',
  '2026-06-18',
  '2026-06-24',
  '2026-06-25',
  '2026-07-02',
  '2026-07-05',
  '2026-07-12',
  '2026-08-23',
  '2026-08-30',
  '2026-08-31',
  '2026-09-07',
  '2026-09-13',
  '2026-09-17',
  '2026-10-25',
  '2026-10-30',
  '2026-11-01',
  '2026-11-11',
  '2026-11-13',
  '2026-11-15',
  '2026-11-16',
  '2026-11-20',
  '2026-11-29',
  '2026-12-04',
  '2026-12-06',
  '2026-12-10',
  '2026-12-13',
  '2026-12-14',
};

bool isSubaMuhurthamDate(String dateKey) => subaMuhurtham2026.contains(dateKey);

/// Labels like `2 வியாழன்` for the சுபமுகூர்த்த தினங்கள் list.
List<String> weddingDayLabelsForMonth(int year, int month) {
  final prefix = '$year-${month.toString().padLeft(2, '0')}-';
  const weekdayTa = [
    'திங்கள்',
    'செவ்வாய்',
    'புதன்',
    'வியாழன்',
    'வெள்ளி',
    'சனி',
    'ஞாயிறு',
  ];
  final keys = subaMuhurtham2026.where((k) => k.startsWith(prefix)).toList()
    ..sort();
  return keys.map((k) {
    final day = int.parse(k.substring(8));
    final dt = DateTime(year, month, day);
    return '$day ${weekdayTa[dt.weekday - 1]}';
  }).toList();
}
