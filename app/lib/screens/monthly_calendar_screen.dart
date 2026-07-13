import 'package:flutter/material.dart';

import '../models/month_calendar.dart';
import '../services/calendar_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/calendar_day_icons.dart';
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
                          padding: const EdgeInsets.fromLTRB(6, 12, 6, 0),
                          child: AppCard(
                            padding: const EdgeInsets.fromLTRB(4, 10, 4, 10),
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
      children: labels.asMap().entries.map((entry) {
        final isSunday = entry.key == 0;
        return Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                entry.value,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isSunday ? AppColors.sundayRed : AppColors.maroon,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        );
      }).toList(),
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
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        // ~10% taller cells for clearer icons / Tamil day.
        childAspectRatio: 0.69,
        crossAxisSpacing: 2,
        mainAxisSpacing: 3,
      ),
      itemCount: days.length,
      itemBuilder: (_, i) {
        final cell = days[i];
        final day = cell.gregorianDay;
        if (day == null) return const SizedBox.shrink();

        Color? bg;
        Color borderColor = Colors.transparent;
        final isHoliday = cell.highlightColor == 'red';
        final isToday = cell.isToday;

        if (isHoliday) {
          bg = AppColors.dailyRed;
        } else if (isToday) {
          bg = AppColors.auspicious;
          borderColor = AppColors.auspicious;
        } else if (cell.isOtherMonth) {
          bg = AppColors.creamDark.withValues(alpha: 0.35);
        } else {
          bg = AppColors.surface;
        }

        final onDark = isHoliday || isToday;
        final topIcons = calendarTopIcons(cell.icons);
        final bottomIcons =
            calendarBottomIcons(cell.icons, moonPhase: cell.moonPhase);
        final iconSize = bottomIcons.length > 2 ? 14.0 : 17.0;

        Color dateColor;
        if (cell.isOtherMonth) {
          dateColor = AppColors.textSecondary.withValues(alpha: 0.45);
        } else if (onDark) {
          dateColor = Colors.white;
        } else if (cell.isSunday) {
          dateColor = AppColors.sundayRed;
        } else {
          dateColor = AppColors.textPrimary;
        }

        Color tamilColor;
        if (onDark) {
          tamilColor = Colors.white.withValues(alpha: 0.85);
        } else if (cell.isOtherMonth) {
          tamilColor = AppColors.textSecondary.withValues(alpha: 0.45);
        } else {
          tamilColor = AppColors.textSecondary.withValues(alpha: 0.75);
        }

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onDayTap(_dateForCell(cell)),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              decoration: BoxDecoration(
                color: bg,
                border: borderColor == Colors.transparent ? null : Border.all(color: borderColor),
                borderRadius: BorderRadius.circular(8),
                boxShadow: isToday
                    ? [
                        BoxShadow(
                          color: AppColors.auspicious.withValues(alpha: 0.28),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ]
                    : null,
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  if (cell.tamilDay != null)
                    Positioned(
                      right: 3,
                      top: 2,
                      child: Text(
                        '${cell.tamilDay}',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                          color: tamilColor,
                        ),
                      ),
                    ),
                  if (topIcons.isNotEmpty)
                    Positioned(
                      left: 1,
                      top: 1,
                      child: CalendarDayIcon(
                        iconId: topIcons.first,
                        size: 18,
                        onDark: onDark,
                        themed: !onDark,
                      ),
                    ),
                  Center(
                    child: Padding(
                      padding: EdgeInsets.only(top: topIcons.isNotEmpty ? 4 : 0),
                      child: Text(
                        '$day',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          height: 1,
                          color: dateColor,
                        ),
                      ),
                    ),
                  ),
                  if (bottomIcons.isNotEmpty)
                    Positioned(
                      left: 1,
                      bottom: 1,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: bottomIcons
                            .take(3)
                            .map(
                              (id) => Padding(
                                padding: const EdgeInsets.only(right: 1),
                                child: CalendarDayIcon(
                                  iconId: id,
                                  size: iconSize,
                                  onDark: onDark,
                                  themed: !onDark,
                                ),
                              ),
                            )
                            .toList(),
                      ),
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
            final iconId = item.icon ?? CalendarDayIcon.iconIdForTitle(item.titleTa);
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                border: isLast
                    ? null
                    : Border(
                        bottom: BorderSide(
                          color: AppColors.creamDark,
                          style: BorderStyle.solid,
                        ),
                      ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: iconId != null
                        ? CalendarDayIcon(iconId: iconId, size: 40, themed: true)
                        : Icon(
                            Icons.restaurant_outlined,
                            color: AppColors.maroon.withValues(alpha: 0.7),
                            size: 28,
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.titleTa,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        height: 1.25,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      item.datesTa,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                        height: 1.3,
                      ),
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
