/// Tamil **solar** month (சௌர மாதம்) start dates for 2026 — Nithra / Prokerala aligned.
///
/// Bug we fix: ingestion mixed lunar `masa` name with `sun_rashi.degree` day,
/// so July 13 showed ஆனி 27 instead of ஆனி 29.
library;

class TamilSolarDay {
  const TamilSolarDay({required this.monthTa, required this.day});

  final String monthTa;
  final int day;
}

/// Inclusive start dates for each Tamil solar month covering calendar year 2026.
/// Next start = end of previous month.
const _starts2026 = <(int y, int m, int d, String name)>[
  (2025, 12, 16, 'மார்கழி'), // into early Jan 2026
  (2026, 1, 15, 'தை'),
  (2026, 2, 13, 'மாசி'),
  (2026, 3, 15, 'பங்குனி'),
  (2026, 4, 14, 'சித்திரை'),
  (2026, 5, 15, 'வைகாசி'),
  (2026, 6, 15, 'ஆனி'), // → Jul 16 (32 days) — July 13 = ஆனி 29
  (2026, 7, 17, 'ஆடி'),
  (2026, 8, 17, 'ஆவணி'),
  (2026, 9, 17, 'புரட்டாசி'),
  (2026, 10, 18, 'ஐப்பசி'),
  (2026, 11, 17, 'கார்த்திகை'),
  (2026, 12, 16, 'மார்கழி'),
  (2027, 1, 14, 'தை'), // sentinel end for Dec 2026 Margazhi
];

TamilSolarDay? tamilSolarDayFor(DateTime date) {
  final dayOnly = DateTime(date.year, date.month, date.day);
  (int, int, int, String)? current;
  for (final start in _starts2026) {
    final startDt = DateTime(start.$1, start.$2, start.$3);
    if (startDt.isAfter(dayOnly)) break;
    current = start;
  }
  if (current == null) return null;
  final startDt = DateTime(current.$1, current.$2, current.$3);
  final dayNum = dayOnly.difference(startDt).inDays + 1;
  return TamilSolarDay(monthTa: current.$4, day: dayNum);
}

int? tamilSolarDayNumber(DateTime date) => tamilSolarDayFor(date)?.day;

String? tamilSolarMonthName(DateTime date) => tamilSolarDayFor(date)?.monthTa;

/// Header like `ஆனி - ஆடி` for a Gregorian month grid.
String tamilMonthsRangeForGregorianMonth(int year, int month) {
  final last = DateTime(year, month + 1, 0).day;
  final names = <String>[];
  for (var d = 1; d <= last; d++) {
    final name = tamilSolarMonthName(DateTime(year, month, d));
    if (name != null && (names.isEmpty || names.last != name)) {
      names.add(name);
    }
  }
  if (names.isEmpty) return '';
  if (names.length == 1) return names.first;
  return '${names.first} - ${names.last}';
}
