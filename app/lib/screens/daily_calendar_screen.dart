import 'package:flutter/material.dart';

import '../models/daily_calendar.dart';
import '../models/month_calendar.dart';
import '../services/calendar_repository.dart';
import '../services/daily_event_details.dart';
import '../theme/app_theme.dart';
import '../widgets/day_events_card.dart';
import '../widgets/native_ad_widget.dart';
import '../widgets/panchangam_glyphs.dart';

/// Daily calendar detail — "இன்றைய பஞ்சாங்கம்" premium layout
/// (deity frame + panchangam grid + auspicious-time cards + rasi palan).
class DailyCalendarScreen extends StatefulWidget {
  const DailyCalendarScreen({
    super.key,
    required this.repository,
    required this.initialDate,
  });

  final CalendarRepository repository;
  final DateTime initialDate;

  @override
  State<DailyCalendarScreen> createState() => _DailyCalendarScreenState();
}

class _DailyCalendarScreenState extends State<DailyCalendarScreen> {
  late DateTime _date;
  DailyCalendar? _day;
  DailyEventDetails? _events;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _date = widget.initialDate;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        widget.repository.getDay(_date),
        widget.repository.getMonth(_date.year, _date.month),
      ]);
      final day = results[0] as DailyCalendar;
      final month = results[1] as MonthCalendar;
      final events = DailyEventResolver.resolve(day: day, month: month);
      if (mounted) {
        setState(() {
          _day = day;
          _events = events;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _shift(int days) {
    setState(() => _date = _date.add(Duration(days: days)));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const NativeAdWidget(),
      backgroundColor: AppColors.softCream,
      appBar: AppBar(
        backgroundColor: AppColors.softCream,
        title: const Text('நாள் காட்டி'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(_error!, textAlign: TextAlign.center),
                  ),
                )
              : _day == null
                  ? const SizedBox.shrink()
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(14, 6, 14, 32),
                      children: [
                        _HeaderCard(day: _day!, onPrev: () => _shift(-1), onNext: () => _shift(1)),
                        const SizedBox(height: 14),
                        if (_events != null && !_events!.isEmpty) DayEventsCard(details: _events!),
                        if (_events != null && !_events!.isEmpty) const SizedBox(height: 14),
                        _PanchangamSection(day: _day!),
                        const SizedBox(height: 14),
                        _AuspiciousTimeCard(
                          title: 'இன்றைய நல்ல நேரம்',
                          slots: _day!.nallaNeram,
                          accent: AppColors.emerald,
                        ),
                        const SizedBox(height: 14),
                        _AuspiciousTimeCard(
                          title: 'இன்றைய கௌரி நல்ல நேரம்',
                          slots: _day!.gowriNallaNeram,
                          accent: AppColors.emerald,
                          checkColor: AppColors.goldDark,
                        ),
                        const SizedBox(height: 14),
                        _InauspiciousCard(slots: _day!.inauspicious),
                        const SizedBox(height: 14),
                        _InfoLines(day: _day!),
                        if (_day!.noteTa.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          _NoteBox(text: _day!.noteTa),
                        ],
                        const SizedBox(height: 14),
                        _RasiChart(cells: _day!.rasiChart, center: _day!.rasiCenterTa),
                        const SizedBox(height: 14),
                        const _PremiumSectionLabel(title: 'இன்றைய ராசி பலன்'),
                        const SizedBox(height: 10),
                        _HoroscopeGrid(items: _day!.horoscope),
                        if (_day!.quoteTa.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          _QuoteCard(quote: _day!.quoteTa),
                        ],
                        if (_day!.birthdaysTa.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          _BirthdayCard(text: _day!.birthdaysTa),
                        ],
                      ],
                    ),
    );
  }
}

/// Premium header — deity-frame placeholder, tamil-month chip and the
/// bold red day number, mirroring the reference panchangam card design.
class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.day, required this.onPrev, required this.onNext});

  final DailyCalendar day;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final monthParts = day.monthLabelTa.split(' - ');
    final monthNameTa = monthParts.isNotEmpty ? monthParts[0] : day.monthLabelTa;
    final weekdayTa = monthParts.length > 1 ? monthParts[1] : '';

    final dateParts = day.gregorianDisplay.split('-');
    final dayNum = dateParts.isNotEmpty ? dateParts[0] : day.gregorianDisplay;
    final year = dateParts.length > 2 ? dateParts[2] : '';

    final tamilChip = day.bannerLineTa.split(',').first.trim();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDecorations.cardRadius),
        border: Border.all(color: AppColors.borderGrey),
        boxShadow: [
          BoxShadow(color: AppColors.crimson.withValues(alpha: 0.08), blurRadius: 18, offset: const Offset(0, 6)),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const DeityFramePlaceholder(),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (tamilChip.isNotEmpty)
                      Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            gradient: AppDecorations.crimsonGradient,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            tamilChip,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _NavButton(icon: Icons.chevron_left_rounded, onPressed: onPrev),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            dayNum,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.numberRed,
                              fontWeight: FontWeight.w900,
                              fontSize: 58,
                              height: 1,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        _NavButton(icon: Icons.chevron_right_rounded, onPressed: onNext),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$monthNameTa $year',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.crimson, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    if (weekdayTa.isNotEmpty)
                      Text(
                        weekdayTa,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (day.subtitleLine1Ta.isNotEmpty || day.subtitleLine2Ta.isNotEmpty) ...[
            const SizedBox(height: 12),
            const _DashedDivider(color: AppColors.borderGrey),
            const SizedBox(height: 10),
            if (day.subtitleLine1Ta.isNotEmpty)
              Text(
                day.subtitleLine1Ta,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            if (day.subtitleLine2Ta.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(
                day.subtitleLine2Ta,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.goldDark, fontWeight: FontWeight.w600, fontSize: 12),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.crimsonSoft,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, color: AppColors.crimson, size: 24),
        ),
      ),
    );
  }
}

/// "இன்றைய பஞ்சாங்கம்" — crimson pill header, 2×2 category grid with hand
/// drawn glyphs, then a compact list for the remaining panchangam facts
/// (சூரிய உதயம் etc.) driven purely by whatever the local database returns.
class _PanchangamSection extends StatelessWidget {
  const _PanchangamSection({required this.day});
  final DailyCalendar day;

  String? _value(String label) {
    for (final item in day.panchangam) {
      if (item.label == label) return item.value;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final tithi = _value('திதி');
    final nakshatram = _value('நட்சத்திரம்');
    final yogam = _value('நாமயோகம்') ?? _value('யோகம்');
    final karanam = _value('கரணம்') ?? _value('கரணன்');

    final primaryLabels = {'திதி', 'நட்சத்திரம்', 'நாமயோகம்', 'யோகம்', 'கரணம்', 'கரணன்', 'சூரிய உதயம்'};
    final extras = day.panchangam.where((e) => !primaryLabels.contains(e.label) && e.value.isNotEmpty).toList();
    final sunrise = _value('சூரிய உதயம்');
    final sunset = _value('சூரிய அஸ்தமனம்');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDecorations.cardRadius),
        border: Border.all(color: AppColors.borderGrey),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: const BoxDecoration(gradient: AppDecorations.crimsonGradient),
            child: const Text(
              'இன்றைய பஞ்சாங்கம்',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 0.3),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _PanchangamCell(
                        kind: PanchangamGlyphKind.tithi,
                        label: 'திதி',
                        value: tithi,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _PanchangamCell(
                        kind: PanchangamGlyphKind.nakshatram,
                        label: 'நட்சத்திரம்',
                        value: nakshatram,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _PanchangamCell(
                        kind: PanchangamGlyphKind.yogam,
                        label: 'யோகம்',
                        value: yogam,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _PanchangamCell(
                        kind: PanchangamGlyphKind.karanam,
                        label: 'கரணம்',
                        value: karanam,
                      ),
                    ),
                  ],
                ),
                if (sunrise != null || sunset != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      if (sunrise != null)
                        Expanded(
                          child: _PanchangamCell(
                            kind: PanchangamGlyphKind.sunrise,
                            label: 'சூரிய உதயம்',
                            value: sunrise,
                            dense: true,
                          ),
                        ),
                      if (sunrise != null && sunset != null) const SizedBox(width: 10),
                      if (sunset != null)
                        Expanded(
                          child: _PanchangamCell(
                            kind: PanchangamGlyphKind.sunset,
                            label: 'சூரிய அஸ்தமனம்',
                            value: sunset,
                            dense: true,
                          ),
                        ),
                    ],
                  ),
                ],
                if (extras.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  ...extras.map(
                    (item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: _PanchangamDetailRow(
                        kind: item.label == 'சந்திராஷ்டமம்' ? PanchangamGlyphKind.moonRasi : PanchangamGlyphKind.yogam,
                        label: item.label,
                        value: item.value,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PanchangamCell extends StatelessWidget {
  const _PanchangamCell({
    required this.kind,
    required this.label,
    required this.value,
    this.dense = false,
  });

  final PanchangamGlyphKind kind;
  final String label;
  final String? value;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppDecorations.softCard(color: AppColors.softCream),
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: dense ? 10 : 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PanchangamGlyphBadge(kind: kind, size: dense ? 24 : 28),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.crimson, fontWeight: FontWeight.bold, fontSize: 12.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value ?? '—',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 12.5, height: 1.35),
          ),
        ],
      ),
    );
  }
}

class _PanchangamDetailRow extends StatelessWidget {
  const _PanchangamDetailRow({required this.kind, required this.label, required this.value});

  final PanchangamGlyphKind kind;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PanchangamGlyphBadge(kind: kind, size: 22, color: AppColors.goldDark),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: AppColors.crimson)),
        ),
        Expanded(
          flex: 3,
          child: Text(value, style: const TextStyle(fontSize: 12.5, color: AppColors.textPrimary, height: 1.3)),
        ),
      ],
    );
  }
}

/// Emerald "good time" card — shared by நல்ல நேரம் and கௌரி நல்ல நேரம்.
class _AuspiciousTimeCard extends StatelessWidget {
  const _AuspiciousTimeCard({
    required this.title,
    required this.slots,
    required this.accent,
    this.checkColor,
  });

  final String title;
  final List<TimeSlot> slots;
  final Color accent;
  final Color? checkColor;

  @override
  Widget build(BuildContext context) {
    if (slots.isEmpty) return const SizedBox.shrink();
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDecorations.cardRadius),
        border: Border.all(color: AppColors.borderGrey),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: const BoxDecoration(gradient: AppDecorations.emeraldGradient),
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 0.3),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              children: slots.map((slot) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      AuspiciousCheckGlyph(size: 22, color: checkColor ?? accent),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          slot.period,
                          style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary, fontSize: 13.5),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.emeraldSoft,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          slot.time,
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.emeraldDark, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _InauspiciousCard extends StatelessWidget {
  const _InauspiciousCard({required this.slots});
  final List<InauspiciousSlot> slots;

  @override
  Widget build(BuildContext context) {
    if (slots.isEmpty) return const SizedBox.shrink();
    return Container(
      decoration: BoxDecoration(
        color: AppColors.crimsonSoft.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(AppDecorations.cardRadius),
        border: Border.all(color: AppColors.inauspicious.withValues(alpha: 0.25)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppColors.inauspicious, size: 18),
              const SizedBox(width: 8),
              Text(
                'தவிர்க்க வேண்டிய நேரம்',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.inauspicious,
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: slots
                .map(
                  (s) => Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppDecorations.cardRadiusSm),
                        border: Border.all(color: AppColors.inauspicious.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        children: [
                          Text(
                            s.name,
                            style: const TextStyle(color: AppColors.inauspicious, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            s.time,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 10.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _InfoLines extends StatelessWidget {
  const _InfoLines({required this.day});
  final DailyCalendar day;

  @override
  Widget build(BuildContext context) {
    final lines = [day.shoolamTa, day.pariharamTa, day.lagnamTa].where((s) => s.isNotEmpty).toList();
    if (lines.isEmpty) return const SizedBox.shrink();
    return Container(
      decoration: AppDecorations.softCard(),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < lines.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            _InfoChip(icon: Icons.compass_calibration_rounded, text: lines[i]),
          ],
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 17, color: AppColors.crimson),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(height: 1.4, fontSize: 12.5, color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }
}

class _NoteBox extends StatelessWidget {
  const _NoteBox({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppDecorations.softCard(),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.crimson, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: const TextStyle(height: 1.5, fontSize: 11.5, color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }
}

class _RasiChart extends StatelessWidget {
  const _RasiChart({required this.cells, required this.center});
  final List<String?> cells;
  final String center;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppDecorations.softCard(),
      padding: const EdgeInsets.all(6),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4),
        itemCount: 16,
        itemBuilder: (_, i) {
          if (i == 5 || i == 6 || i == 9 || i == 10) {
            if (i == 5) {
              return Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: AppColors.crimsonSoft,
                  border: Border.all(color: AppColors.crimson.withValues(alpha: 0.2)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    center,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.crimson),
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          }
          final text = i < cells.length ? cells[i] : null;
          return Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.borderGrey),
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.center,
            child: Text(text ?? '', style: const TextStyle(fontSize: 11)),
          );
        },
      ),
    );
  }
}

class _PremiumSectionLabel extends StatelessWidget {
  const _PremiumSectionLabel({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        decoration: BoxDecoration(
          gradient: AppDecorations.crimsonGradient,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          title,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5),
        ),
      ),
    );
  }
}

class _HoroscopeGrid extends StatelessWidget {
  const _HoroscopeGrid({required this.items});
  final List<HoroscopeItem> items;

  static const _signColors = [
    AppColors.dailyRed,
    AppColors.goldDark,
    AppColors.emerald,
    AppColors.labelPink,
    AppColors.crimson,
    AppColors.monthlyGreen,
  ];

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: items.asMap().entries.map((entry) {
        final h = entry.value;
        final color = _signColors[entry.key % _signColors.length];
        return SizedBox(
          width: (MediaQuery.of(context).size.width - 38) / 2,
          child: Container(
            decoration: AppDecorations.softCard(),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        h.sign,
                        style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(h.prediction, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _QuoteCard extends StatelessWidget {
  const _QuoteCard({required this.quote});
  final String quote;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppDecorations.goldBorder(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.format_quote_rounded, color: AppColors.goldDark, size: 26),
              const SizedBox(width: 8),
              const Text(
                'பொன்மொழி',
                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.goldDark, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            quote,
            style: const TextStyle(fontStyle: FontStyle.italic, height: 1.6, fontSize: 13, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}

class _BirthdayCard extends StatelessWidget {
  const _BirthdayCard({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppDecorations.softCard(),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.crimsonSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.cake_rounded, color: AppColors.crimson, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('பிறந்த நாள்', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                const SizedBox(height: 6),
                Text(text, style: const TextStyle(height: 1.5, fontSize: 12.5, color: AppColors.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedDivider extends StatelessWidget {
  const _DashedDivider({this.color = AppColors.creamDark});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const dashWidth = 4.0;
        const dashSpace = 3.0;
        final dashCount = (constraints.maxWidth / (dashWidth + dashSpace)).floor();
        return Row(
          children: List.generate(dashCount, (_) {
            return Container(
              width: dashWidth,
              height: 1,
              margin: const EdgeInsets.only(right: dashSpace),
              color: color,
            );
          }),
        );
      },
    );
  }
}
