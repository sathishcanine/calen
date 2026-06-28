import 'package:flutter/material.dart';

import '../models/month_calendar.dart';
import '../services/calendar_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/kolam_pattern.dart';
import '../widgets/native_ad_widget.dart';
import '../widgets/section_header.dart';
import 'daily_calendar_screen.dart';

/// SS5–SS7 — Monthly grid and festival lists.
class MonthlyCalendarScreen extends StatefulWidget {
  const MonthlyCalendarScreen({
    super.key,
    required this.repository,
    required this.year,
    required this.month,
  });

  final CalendarRepository repository;
  final int year;
  final int month;

  @override
  State<MonthlyCalendarScreen> createState() => _MonthlyCalendarScreenState();
}

class _MonthlyCalendarScreenState extends State<MonthlyCalendarScreen> {
  MonthCalendar? _data;
  bool _loading = true;
  String? _error;
  late int _year;
  late int _month;

  static const _weekdays = ['ஞா', 'தி', 'செ', 'பு', 'வி', 'வெ', 'ச'];

  @override
  void initState() {
    super.initState();
    _year = widget.year;
    _month = widget.month;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await widget.repository.getMonth(_year, _month);
      if (mounted) setState(() => _data = data);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _changeMonth(int delta) {
    var m = _month + delta;
    var y = _year;
    if (m > 12) {
      m = 1;
      y++;
    } else if (m < 1) {
      m = 12;
      y--;
    }
    setState(() {
      _month = m;
      _year = y;
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const NativeAdWidget(),
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('மாத காட்டி'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.maroon.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('$_year', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.maroon)),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _data == null
                  ? const SizedBox.shrink()
                  : ListView(
                      padding: const EdgeInsets.only(bottom: 32),
                      children: [
                        _MonthHeader(
                          label: _data!.monthLabelTa,
                          tamilMonths: _data!.tamilMonthsTa,
                          onPrev: () => _changeMonth(-1),
                          onNext: () => _changeMonth(1),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                          child: AppCard(
                            padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
                            child: Column(
                              children: [
                                _WeekdayRow(labels: _weekdays),
                                _CalendarGrid(
                                  days: _data!.days,
                                  year: _year,
                                  month: _month,
                                  onDayTap: (date) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => DailyCalendarScreen(
                                          repository: widget.repository,
                                          initialDate: date,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SectionHeader(title: 'விரத தினங்கள்', icon: Icons.restaurant_rounded),
                        _FastingList(items: _data!.fastingDays),
                        const SectionHeader(title: 'சுபமுகூர்த்த தினங்கள்', icon: Icons.favorite_rounded),
                        _SimpleList(strings: _data!.weddingDays),
                        const SectionHeader(title: 'மற்ற தினங்கள்', icon: Icons.event_note_rounded),
                        _OtherDaysGrid(items: _data!.otherDays),
                        const SectionHeader(title: 'இந்து பண்டிகைகள்', icon: Icons.temple_hindu_rounded),
                        _FestivalList(items: _data!.hinduFestivals, accent: AppColors.maroon),
                        const SectionHeader(title: 'முஸ்லீம் பண்டிகைகள்', icon: Icons.mosque_rounded),
                        _FestivalList(items: _data!.muslimFestivals, accent: AppColors.monthlyGreen),
                        const SectionHeader(title: 'கிறிஸ்தவ பண்டிகைகள்', icon: Icons.church_rounded),
                        _FestivalList(items: _data!.christianFestivals, accent: AppColors.goldDark),
                        const SectionHeader(title: 'அரசு விடுமுறை நாட்கள்', icon: Icons.flag_rounded),
                        _FestivalList(items: _data!.governmentHolidays, accent: AppColors.dailyRed),
                      ],
                    ),
    );
  }
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({
    required this.label,
    required this.tamilMonths,
    required this.onPrev,
    required this.onNext,
  });

  final String label;
  final String tamilMonths;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppDecorations.headerGradient),
      child: KolamPattern(
        opacity: 0.1,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _NavButton(icon: Icons.chevron_left_rounded, onPressed: onPrev),
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(width: 12),
                  _NavButton(icon: Icons.chevron_right_rounded, onPressed: onNext),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                tamilMonths,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.goldLight),
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
          padding: const EdgeInsets.all(6),
          child: Icon(icon, color: Colors.white, size: 26),
        ),
      ),
    );
  }
}

class _WeekdayRow extends StatelessWidget {
  const _WeekdayRow({required this.labels});
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: labels
          .map(
            (d) => Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(
                    d,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.maroon,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  const _CalendarGrid({
    required this.days,
    required this.year,
    required this.month,
    required this.onDayTap,
  });

  final List<MonthDayCell> days;
  final int year;
  final int month;
  final ValueChanged<DateTime> onDayTap;

  DateTime _dateForCell(MonthDayCell cell) {
    final day = cell.gregorianDay!;
    if (!cell.isOtherMonth) return DateTime(year, month, day);
    if (day > 15) return DateTime(year, month - 1, day);
    return DateTime(year, month + 1, day);
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 0.9,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: days.length,
      itemBuilder: (_, i) {
        final cell = days[i];
        final day = cell.gregorianDay;
        if (day == null) return const SizedBox.shrink();

        Color? bg;
        Color borderColor = AppColors.creamDark;
        if (cell.isToday) {
          bg = AppColors.auspicious;
          borderColor = AppColors.auspicious;
        } else if (cell.highlightColor == 'red') {
          bg = AppColors.dailyRed;
          borderColor = AppColors.dailyRed;
        }

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onDayTap(_dateForCell(cell)),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              decoration: BoxDecoration(
                color: bg ?? (cell.isOtherMonth ? AppColors.creamDark.withValues(alpha: 0.4) : AppColors.surface),
                border: Border.all(color: borderColor),
                borderRadius: BorderRadius.circular(10),
                boxShadow: cell.isToday
                    ? [
                        BoxShadow(
                          color: AppColors.auspicious.withValues(alpha: 0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Stack(
                children: [
                  if (cell.tamilDay != null)
                    Positioned(
                      right: 4,
                      top: 3,
                      child: Text(
                        '${cell.tamilDay}',
                        style: TextStyle(
                          fontSize: 9,
                          color: bg != null ? Colors.white70 : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  Center(
                    child: Text(
                      '$day',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: cell.isSunday
                            ? AppColors.sundayRed
                            : cell.isOtherMonth
                                ? AppColors.textSecondary.withValues(alpha: 0.5)
                                : (bg != null ? Colors.white : AppColors.textPrimary),
                      ),
                    ),
                  ),
                  if (cell.moonPhase == 'amavasai')
                    Positioned(
                      bottom: 3,
                      left: 6,
                      child: Icon(Icons.circle, size: 7, color: bg != null ? Colors.white70 : Colors.black54),
                    ),
                  if (cell.moonPhase == 'pournami')
                    Positioned(
                      bottom: 3,
                      left: 6,
                      child: Icon(Icons.circle_outlined, size: 7, color: bg != null ? Colors.white70 : Colors.black54),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DateChips extends StatelessWidget {
  const _DateChips({required this.dates, required this.accent});

  final String dates;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final parts = dates.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: parts
          .map(
            (d) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: accent.withValues(alpha: 0.18)),
              ),
              child: Text(
                d,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: accent),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _FastingList extends StatelessWidget {
  const _FastingList({required this.items});
  final List<MonthListItem> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: AppCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: items.asMap().entries.map((entry) {
            final item = entry.value;
            final isLast = entry.key == items.length - 1;
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                border: isLast ? null : Border(bottom: BorderSide(color: AppColors.creamDark)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.maroon.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.restaurant_outlined, color: AppColors.maroon, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item.titleTa,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.only(left: 46),
                    child: _DateChips(dates: item.datesTa, accent: AppColors.maroon),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _SimpleList extends StatelessWidget {
  const _SimpleList({required this.strings});
  final List<String> strings;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: AppCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: strings.asMap().entries.map((entry) {
            final isLast = entry.key == strings.length - 1;
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                border: isLast ? null : Border(bottom: BorderSide(color: AppColors.creamDark)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(Icons.favorite_rounded, color: AppColors.labelPink.withValues(alpha: 0.7), size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: const TextStyle(fontSize: 14, height: 1.5),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _OtherDaysGrid extends StatelessWidget {
  const _OtherDaysGrid({required this.items});
  final List<Map<String, dynamic>> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: AppCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: items.asMap().entries.map((entry) {
            final item = entry.value;
            final isLast = entry.key == items.length - 1;
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                border: isLast ? null : Border(bottom: BorderSide(color: AppColors.creamDark)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${item['title']}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 10),
                  _DateChips(dates: '${item['dates']}', accent: AppColors.goldDark),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _FestivalList extends StatelessWidget {
  const _FestivalList({required this.items, required this.accent});
  final List<Map<String, dynamic>> items;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: AppCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: items.asMap().entries.map((entry) {
            final f = entry.value;
            final isLast = entry.key == items.length - 1;
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                border: isLast ? null : Border(bottom: BorderSide(color: AppColors.creamDark)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [accent, accent.withValues(alpha: 0.7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${f['day']}',
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${f['title']}',
                    style: const TextStyle(fontSize: 14, height: 1.5),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
