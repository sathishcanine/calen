import 'package:flutter/material.dart';

import '../models/daily_calendar.dart';
import '../services/calendar_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/kolam_pattern.dart';
import '../widgets/native_ad_widget.dart';
import '../widgets/section_header.dart';

/// SS2–SS4 — Daily calendar detail (panchangam, horoscope, quote).
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
      final day = await widget.repository.getDay(_date);
      if (mounted) setState(() => _day = day);
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
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('நாள் காட்டி')),
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
                      padding: const EdgeInsets.only(bottom: 32),
                      children: [
                        _HeaderBlock(day: _day!, onPrev: () => _shift(-1), onNext: () => _shift(1)),
                        if (_day!.eventsTa.isNotEmpty) _EventsBlock(text: _day!.eventsTa),
                        _TimeSection(
                          title: 'நல்ல நேரம்',
                          icon: Icons.wb_sunny_rounded,
                          accent: AppColors.auspicious,
                          slots: _day!.nallaNeram,
                        ),
                        _TimeSection(
                          title: 'கௌரி நல்ல நேரம்',
                          icon: Icons.star_rounded,
                          accent: AppColors.goldDark,
                          slots: _day!.gowriNallaNeram,
                        ),
                        const SectionHeader(title: 'பஞ்சாங்கம்', icon: Icons.nightlight_round),
                        _PanchangamGrid(items: _day!.panchangam),
                        _InauspiciousRow(slots: _day!.inauspicious),
                        _InfoLines(day: _day!),
                        if (_day!.noteTa.isNotEmpty) _NoteBox(text: _day!.noteTa),
                        _RasiChart(cells: _day!.rasiChart, center: _day!.rasiCenterTa),
                        const SectionHeader(title: 'இன்றைய ராசிபலன்', icon: Icons.auto_awesome),
                        _HoroscopeGrid(items: _day!.horoscope),
                        _QuoteCard(quote: _day!.quoteTa),
                        _BirthdayCard(text: _day!.birthdaysTa),
                      ],
                    ),
    );
  }
}

class _HeaderBlock extends StatelessWidget {
  const _HeaderBlock({required this.day, required this.onPrev, required this.onNext});

  final DailyCalendar day;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final parts = day.gregorianDisplay.split('-');
    final dayNum = parts.isNotEmpty ? parts[0] : day.gregorianDisplay;

    return Container(
      decoration: const BoxDecoration(gradient: AppDecorations.headerGradient),
      child: KolamPattern(
        opacity: 0.1,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 20, 8, 24),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
                ),
                child: Text(
                  day.monthLabelTa,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.goldLight,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _NavButton(icon: Icons.chevron_left_rounded, onPressed: onPrev),
                  const SizedBox(width: 8),
                  Text(
                    dayNum,
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          height: 1,
                        ),
                  ),
                  const SizedBox(width: 8),
                  _NavButton(icon: Icons.chevron_right_rounded, onPressed: onNext),
                ],
              ),
              Text(
                day.gregorianDisplay,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: 12),
              Text(
                day.subtitleLine1Ta,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: 0.9)),
              ),
              const SizedBox(height: 4),
              Text(
                day.subtitleLine2Ta,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.goldLight),
              ),
            ],
          ),
        ),
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
      color: Colors.white.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}

class _EventsBlock extends StatelessWidget {
  const _EventsBlock({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: AppCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.maroon.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.celebration_rounded, color: AppColors.maroon, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(text, style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5)),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeSection extends StatelessWidget {
  const _TimeSection({
    required this.title,
    required this.icon,
    required this.accent,
    required this.slots,
  });

  final String title;
  final IconData icon;
  final Color accent;
  final List<TimeSlot> slots;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SectionHeader(title: title, icon: icon),
        Padding(
          padding: const EdgeInsets.all(16),
          child: AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: slots.asMap().entries.map((entry) {
                final isLast = entry.key == slots.length - 1;
                final s = entry.value;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    border: isLast ? null : Border(bottom: BorderSide(color: AppColors.creamDark)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(s.period, style: TextStyle(color: AppColors.textSecondary))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          s.time,
                          style: TextStyle(fontWeight: FontWeight.bold, color: accent),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}

class _PanchangamGrid extends StatelessWidget {
  const _PanchangamGrid({required this.items});
  final List<PanchangamItem> items;

  static const _icons = [
    Icons.wb_sunny_outlined,
    Icons.access_time_rounded,
    Icons.brightness_2_outlined,
    Icons.star_outline_rounded,
    Icons.water_drop_outlined,
    Icons.calendar_today_outlined,
    Icons.nightlight_outlined,
    Icons.public_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.35,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: items.length,
        itemBuilder: (_, i) {
          final item = items[i];
          final icon = i < _icons.length ? _icons[i] : Icons.info_outline_rounded;
          return AppCard(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 16, color: AppColors.labelPink),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        item.label,
                        style: const TextStyle(
                          color: AppColors.labelPink,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Text(
                    item.value,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.4),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InauspiciousRow extends StatelessWidget {
  const _InauspiciousRow({required this.slots});
  final List<InauspiciousSlot> slots;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: AppCard(
        color: AppColors.inauspicious.withValues(alpha: 0.06),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: AppColors.inauspicious, size: 20),
                const SizedBox(width: 8),
                Text(
                  'தவிர்க்க வேண்டிய நேரம்',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.inauspicious,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: slots
                  .map(
                    (s) => Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                        decoration: BoxDecoration(
                          color: AppColors.inauspicious.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppDecorations.cardRadiusSm),
                          border: Border.all(color: AppColors.inauspicious.withValues(alpha: 0.2)),
                        ),
                        child: Column(
                          children: [
                            Text(
                              s.name,
                              style: const TextStyle(
                                color: AppColors.inauspicious,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              s.time,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 10),
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
      ),
    );
  }
}

class _InfoLines extends StatelessWidget {
  const _InfoLines({required this.day});
  final DailyCalendar day;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InfoChip(icon: Icons.compass_calibration_rounded, text: day.shoolamTa),
            const SizedBox(height: 8),
            _InfoChip(icon: Icons.healing_rounded, text: day.pariharamTa),
            const SizedBox(height: 8),
            _InfoChip(icon: Icons.timeline_rounded, text: day.lagnamTa),
          ],
        ),
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
        Icon(icon, size: 18, color: AppColors.maroon),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.4))),
      ],
    );
  }
}

class _NoteBox extends StatelessWidget {
  const _NoteBox({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: AppCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline_rounded, color: AppColors.maroon, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(text, style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.5)),
            ),
          ],
        ),
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
    return Padding(
      padding: const EdgeInsets.all(16),
      child: AppCard(
        padding: const EdgeInsets.all(4),
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
                    color: AppColors.maroon.withValues(alpha: 0.08),
                    border: Border.all(color: AppColors.maroon.withValues(alpha: 0.2)),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Text(
                      center,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.maroon),
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
                border: Border.all(color: AppColors.creamDark),
                borderRadius: BorderRadius.circular(6),
              ),
              alignment: Alignment.center,
              child: Text(text ?? '', style: const TextStyle(fontSize: 11)),
            );
          },
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
    AppColors.auspicious,
    AppColors.labelPink,
    AppColors.maroon,
    AppColors.monthlyGreen,
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: items.asMap().entries.map((entry) {
          final h = entry.value;
          final color = _signColors[entry.key % _signColors.length];
          return SizedBox(
            width: (MediaQuery.of(context).size.width - 42) / 2,
            child: AppCard(
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
                  Text(h.prediction, style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.4)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _QuoteCard extends StatelessWidget {
  const _QuoteCard({required this.quote});
  final String quote;

  @override
  Widget build(BuildContext context) {
    if (quote.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: AppCard(
        goldAccent: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.format_quote_rounded, color: AppColors.goldDark, size: 28),
                const SizedBox(width: 8),
                Text(
                  'பொன்மொழி',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.goldDark,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              quote,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontStyle: FontStyle.italic,
                    height: 1.6,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BirthdayCard extends StatelessWidget {
  const _BirthdayCard({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: AppCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.labelPink.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.cake_rounded, color: AppColors.labelPink, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'பிறந்த நாள்',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(text, style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
