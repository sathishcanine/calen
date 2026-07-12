import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/daily_calendar.dart';
import '../models/month_calendar.dart';
import '../services/calendar_repository.dart';
import '../services/daily_event_details.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/day_events_card.dart';
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
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: _loading
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
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 32),
                children: [
                  const _InlineBackButton(),
                  _HeaderBlock(
                    day: _day!,
                    onPrev: () => _shift(-1),
                    onNext: () => _shift(1),
                  ),
                  _TimeSection(
                    title: 'நல்ல நேரம்',
                    iconId: 'check',
                    accent: const Color(0xFF15803D),
                    slots: _day!.nallaNeram,
                  ),
                  _TimeSection(
                    title: 'கௌரி நல்ல நேரம்',
                    iconId: 'star',
                    accent: AppColors.goldDark,
                    slots: _day!.gowriNallaNeram,
                  ),
                  _InauspiciousRow(slots: _day!.inauspicious),
                  _InfoLines(day: _day!),
                  if (_events != null && !_events!.isEmpty)
                    DayEventsCard(details: _events!),
                  const SectionHeader(title: 'பஞ்சாங்கம்'),
                  _PanchangamGrid(items: _day!.panchangam),
                  if (_day!.noteTa.isNotEmpty) _NoteBox(text: _day!.noteTa),
                  _RasiChart(
                    cells: _day!.rasiChart,
                    center: _day!.rasiCenterTa,
                  ),
                  const SectionHeader(
                    title: 'இன்றைய ராசிபலன்',
                    icon: Icons.auto_awesome,
                  ),
                  _HoroscopeGrid(items: _day!.horoscope),
                  _QuoteCard(quote: _day!.quoteTa),
                  _BirthdayCard(text: _day!.birthdaysTa),
                ],
              ),
      ),
    );
  }
}

class _InlineBackButton extends StatelessWidget {
  const _InlineBackButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: Align(
        alignment: Alignment.centerLeft,
        child: IconButton(
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(width: 36, height: 32),
          icon: const Icon(Icons.arrow_back, color: AppColors.maroon),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
    );
  }
}

class _HeaderBlock extends StatelessWidget {
  const _HeaderBlock({
    required this.day,
    required this.onPrev,
    required this.onNext,
  });

  final DailyCalendar day;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final parts = day.gregorianDisplay.split('-');
    final dayNum = parts.isNotEmpty ? parts[0] : day.gregorianDisplay;
    final weekday = _weekdayFromBanner(day.bannerLineTa);
    final dateTitle = _gregorianTamilTitle(day.gregorianDate, weekday);
    final tamilMonthTitle = _tamilMonthTitle(day.bannerLineTa);

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 10),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 18),
            padding: const EdgeInsets.fromLTRB(10, 24, 10, 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFDF6).withValues(alpha: 0.98),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.2)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.maroon.withValues(alpha: 0.07),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _DeityFrame(size: 138, kind: _selectDeity(day)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        tamilMonthTitle,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w900,
                          height: 1.08,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _NavButton(
                            icon: Icons.chevron_left_rounded,
                            onPressed: onPrev,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            dayNum.padLeft(2, '0'),
                            style: Theme.of(context).textTheme.displayLarge
                                ?.copyWith(
                                  color: const Color(0xFFDC2626),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 74,
                                  letterSpacing: -3,
                                  height: 0.88,
                                ),
                          ),
                          const SizedBox(width: 8),
                          _NavButton(
                            icon: Icons.chevron_right_rounded,
                            onPressed: onNext,
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _gregorianMonthYearTa(day.gregorianDate),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w900,
                              height: 1.15,
                            ),
                      ),
                      Text(
                        weekday,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 7),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE11D48), Color(0xFFDB2777)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE11D48).withValues(alpha: 0.24),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              dateTitle,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeityFrame extends StatelessWidget {
  const _DeityFrame({required this.size, required this.kind});

  final double size;
  final _DeityKind kind;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        _deityAsset(kind),
        fit: BoxFit.contain,
        alignment: Alignment.center,
      ),
    );
  }
}

enum _DeityKind { murugan, shivan, perumaal, surya, dakshinamurthy, lakshmi }

String _deityAsset(_DeityKind kind) {
  return switch (kind) {
    _DeityKind.murugan => 'assets/images/gods/god_murugan.png',
    _DeityKind.shivan => 'assets/images/gods/god_shivan.png',
    _DeityKind.perumaal => 'assets/images/gods/god_perumaal.png',
    _DeityKind.surya => 'assets/images/gods/god_surya.png',
    _DeityKind.dakshinamurthy => 'assets/images/gods/god_dakshinamurthy.png',
    _DeityKind.lakshmi => 'assets/images/gods/god_lakshmi.png',
  };
}

_DeityKind _selectDeity(DailyCalendar day) {
  final weekday = _weekdayFromBanner(day.bannerLineTa);
  final tithi = _panchangamValue(day, 'திதி');
  final nakshatram = _panchangamValue(day, 'நட்சத்திரம்');
  final month = day.monthLabelTa;
  final eventText = day.eventsTa;

  if (tithi.contains('சஷ்டி') ||
      weekday.contains('செவ்வாய்') ||
      nakshatram.contains('கார்த்திகை') ||
      nakshatram.contains('கிருத்திகை')) {
    return _DeityKind.murugan;
  }
  if (weekday.contains('திங்கள்') ||
      tithi.contains('திரயோதசி') ||
      (tithi.contains('சதுர்த்தசி') && tithi.contains('தேய்பிறை')) ||
      eventText.contains('பிரதோஷ') ||
      eventText.contains('சிவராத்திரி') ||
      nakshatram.contains('திருவாதிரை')) {
    return _DeityKind.shivan;
  }
  if (weekday.contains('புதன்') ||
      weekday.contains('சனி') ||
      tithi.contains('ஏகாதசி') ||
      month.contains('புரட்டாசி')) {
    return _DeityKind.perumaal;
  }
  if (weekday.contains('ஞாயிறு') ||
      (tithi.contains('வளர்பிறை') && tithi.contains('சப்தமி')) ||
      eventText.contains('ரத சப்தமி')) {
    return _DeityKind.surya;
  }
  if (weekday.contains('வியாழ') ||
      nakshatram.contains('புனர்பூசம்') ||
      nakshatram.contains('விசாகம்') ||
      nakshatram.contains('பூரட்டாதி')) {
    return _DeityKind.dakshinamurthy;
  }
  if (weekday.contains('வெள்ளி')) {
    return _DeityKind.lakshmi;
  }
  return _DeityKind.murugan;
}

String _panchangamValue(DailyCalendar day, String label) {
  for (final item in day.panchangam) {
    if (item.label == label) return item.value;
  }
  return '';
}

String _weekdayFromBanner(String banner) {
  if (!banner.contains(',')) return '';
  return banner.split(',').last.trim();
}

String _tamilMonthTitle(String banner) {
  final title = banner.contains(',')
      ? banner.split(',').first.trim()
      : banner.trim();
  return title.isEmpty ? '' : title.replaceAll(RegExp(r'\s+'), ' ');
}

String _gregorianTamilTitle(DateTime date, String weekday) {
  final day = date.day.toString().padLeft(2, '0');
  final month = _gregorianMonthTa(date.month);
  final suffix = weekday.isEmpty ? '' : ' - $weekday';
  return '$day $month ${date.year}$suffix';
}

String _gregorianMonthYearTa(DateTime date) {
  return '${_gregorianMonthTa(date.month)} ${date.year}';
}

String _gregorianMonthTa(int month) {
  const names = [
    'ஜனவரி',
    'பிப்ரவரி',
    'மார்ச்',
    'ஏப்ரல்',
    'மே',
    'ஜூன்',
    'ஜூலை',
    'ஆகஸ்ட்',
    'செப்டம்பர்',
    'அக்டோபர்',
    'நவம்பர்',
    'டிசம்பர்',
  ];
  if (month < 1 || month > names.length) return '';
  return names[month - 1];
}

class _NavButton extends StatelessWidget {
  const _NavButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF9D174D).withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, color: const Color(0xFF9D174D), size: 24),
        ),
      ),
    );
  }
}

class _TimeSection extends StatelessWidget {
  const _TimeSection({
    required this.title,
    required this.iconId,
    required this.accent,
    required this.slots,
  });

  final String title;
  final String iconId;
  final Color accent;
  final List<TimeSlot> slots;

  @override
  Widget build(BuildContext context) {
    if (slots.isEmpty) return const SizedBox.shrink();
    return _PremiumSectionCard(
      title: title,
      titleColor: accent,
      child: Column(
        children: slots.asMap().entries.map((entry) {
          final isLast = entry.key == slots.length - 1;
          final slot = entry.value;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              border: isLast
                  ? null
                  : Border(
                      bottom: BorderSide(
                        color: AppColors.creamDark.withValues(alpha: 0.75),
                      ),
                    ),
            ),
            child: Row(
              children: [
                _RoundVectorIcon(iconId: iconId, color: accent, size: 24),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    slot.period,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.11),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    slot.time,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _PremiumSectionCard extends StatelessWidget {
  const _PremiumSectionCard({
    required this.title,
    required this.titleColor,
    required this.child,
  });

  final String title;
  final Color titleColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 12),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topLeft,
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 18),
            padding: const EdgeInsets.fromLTRB(14, 22, 14, 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.28)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.maroon.withValues(alpha: 0.06),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: child,
          ),
          Container(
            margin: const EdgeInsets.only(left: 18),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  titleColor == const Color(0xFF15803D)
                      ? const Color(0xFF166534)
                      : const Color(0xFF741238),
                  titleColor == const Color(0xFF15803D)
                      ? const Color(0xFF15803D)
                      : const Color(0xFF9D174D),
                ],
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: titleColor.withValues(alpha: 0.22),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _RoundVectorIcon(
                  iconId: 'mini_$title',
                  color: AppColors.goldLight,
                  size: 17,
                  filled: false,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PanchangamVectorIcon extends StatelessWidget {
  const _PanchangamVectorIcon({required this.iconId, required this.size});

  final String iconId;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _PanchangamVectorPainter(iconId: iconId)),
    );
  }
}

class _RoundVectorIcon extends StatelessWidget {
  const _RoundVectorIcon({
    required this.iconId,
    required this.color,
    required this.size,
    this.filled = true,
  });

  final String iconId;
  final Color color;
  final double size;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RoundVectorPainter(
          iconId: iconId,
          color: color,
          filled: filled,
        ),
      ),
    );
  }
}

class _PanchangamVectorPainter extends CustomPainter {
  _PanchangamVectorPainter({required this.iconId});

  final String iconId;

  @override
  void paint(Canvas canvas, Size s) {
    final stroke = Paint()
      ..color = AppColors.textPrimary
      ..strokeWidth = s.width * 0.07
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final fill = Paint()..color = const Color(0xFFFFF7ED);
    canvas.drawCircle(Offset(s.width / 2, s.height / 2), s.width * 0.48, fill);

    switch (iconId) {
      case 'tithi':
        canvas.drawArc(
          Rect.fromCircle(
            center: Offset(s.width * 0.52, s.height * 0.5),
            radius: s.width * 0.3,
          ),
          -math.pi / 2,
          math.pi * 1.35,
          false,
          stroke,
        );
        canvas.drawCircle(
          Offset(s.width * 0.35, s.height * 0.32),
          s.width * 0.05,
          Paint()..color = AppColors.textPrimary,
        );
      case 'nakshatram':
        final star = Path();
        for (var i = 0; i < 5; i++) {
          final a = -math.pi / 2 + i * math.pi * 2 / 5;
          final r = i == 0 ? s.width * 0.31 : s.width * 0.31;
          final x = s.width / 2 + math.cos(a) * r;
          final y = s.height / 2 + math.sin(a) * r;
          if (i == 0) {
            star.moveTo(x, y);
          } else {
            star.lineTo(x, y);
          }
          final b = a + math.pi / 5;
          star.lineTo(
            s.width / 2 + math.cos(b) * s.width * 0.14,
            s.height / 2 + math.sin(b) * s.width * 0.14,
          );
        }
        star.close();
        canvas.drawPath(star, Paint()..color = AppColors.goldDark);
      case 'yogam':
        canvas.drawCircle(
          Offset(s.width * 0.38, s.height * 0.42),
          s.width * 0.13,
          Paint()..color = AppColors.maroon,
        );
        canvas.drawCircle(
          Offset(s.width * 0.62, s.height * 0.58),
          s.width * 0.13,
          Paint()..color = AppColors.goldDark,
        );
        canvas.drawLine(
          Offset(s.width * 0.46, s.height * 0.49),
          Offset(s.width * 0.54, s.height * 0.51),
          stroke,
        );
      case 'karanam':
        final path = Path()
          ..moveTo(s.width * 0.28, s.height * 0.7)
          ..quadraticBezierTo(
            s.width * 0.48,
            s.height * 0.2,
            s.width * 0.72,
            s.height * 0.66,
          )
          ..quadraticBezierTo(
            s.width * 0.48,
            s.height * 0.78,
            s.width * 0.28,
            s.height * 0.7,
          );
        canvas.drawPath(
          path,
          Paint()..color = AppColors.maroon.withValues(alpha: 0.9),
        );
      default:
        canvas.drawCircle(
          Offset(s.width / 2, s.height / 2),
          s.width * 0.18,
          Paint()..color = AppColors.maroon,
        );
    }
  }

  @override
  bool shouldRepaint(covariant _PanchangamVectorPainter oldDelegate) =>
      oldDelegate.iconId != iconId;
}

class _RoundVectorPainter extends CustomPainter {
  _RoundVectorPainter({
    required this.iconId,
    required this.color,
    required this.filled,
  });

  final String iconId;
  final Color color;
  final bool filled;

  @override
  void paint(Canvas canvas, Size s) {
    final bg = Paint()
      ..color = filled ? color : color.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(s.width / 2, s.height / 2), s.width * 0.48, bg);
    final mark = Paint()
      ..color = filled ? Colors.white : color
      ..strokeWidth = s.width * 0.12
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    if (iconId == 'check') {
      final path = Path()
        ..moveTo(s.width * 0.28, s.height * 0.52)
        ..lineTo(s.width * 0.44, s.height * 0.67)
        ..lineTo(s.width * 0.72, s.height * 0.35);
      canvas.drawPath(path, mark);
      return;
    }

    if (iconId.contains('sunrise') || iconId.contains('sunset')) {
      final center = Offset(s.width * 0.5, s.height * 0.58);
      canvas.drawCircle(center, s.width * 0.16, Paint()..color = color);
      for (var i = 0; i < 8; i++) {
        final angle = -math.pi + i * math.pi / 7;
        canvas.drawLine(
          center + Offset(math.cos(angle), math.sin(angle)) * s.width * 0.24,
          center + Offset(math.cos(angle), math.sin(angle)) * s.width * 0.34,
          Paint()
            ..color = color
            ..strokeWidth = s.width * 0.045
            ..strokeCap = StrokeCap.round,
        );
      }
      canvas.drawLine(
        Offset(s.width * 0.18, s.height * 0.76),
        Offset(s.width * 0.82, s.height * 0.76),
        mark,
      );
      return;
    }

    if (iconId.contains('moon')) {
      canvas.drawArc(
        Rect.fromCircle(
          center: Offset(s.width * 0.52, s.height * 0.48),
          radius: s.width * 0.22,
        ),
        math.pi * 0.25,
        math.pi * 1.4,
        false,
        mark,
      );
      canvas.drawCircle(
        Offset(s.width * 0.72, s.height * 0.32),
        s.width * 0.035,
        Paint()..color = color,
      );
      return;
    }

    final star = Path();
    for (var i = 0; i < 5; i++) {
      final a = -math.pi / 2 + i * math.pi * 2 / 5;
      if (i == 0) {
        star.moveTo(
          s.width / 2 + math.cos(a) * s.width * 0.28,
          s.height / 2 + math.sin(a) * s.width * 0.28,
        );
      } else {
        star.lineTo(
          s.width / 2 + math.cos(a) * s.width * 0.28,
          s.height / 2 + math.sin(a) * s.width * 0.28,
        );
      }
      final b = a + math.pi / 5;
      star.lineTo(
        s.width / 2 + math.cos(b) * s.width * 0.12,
        s.height / 2 + math.sin(b) * s.width * 0.12,
      );
    }
    star.close();
    canvas.drawPath(star, Paint()..color = filled ? Colors.white : color);
  }

  @override
  bool shouldRepaint(covariant _RoundVectorPainter oldDelegate) =>
      oldDelegate.iconId != iconId ||
      oldDelegate.color != color ||
      oldDelegate.filled != filled;
}

class _PanchangamGrid extends StatelessWidget {
  const _PanchangamGrid({required this.items});
  final List<PanchangamItem> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.45,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: items.length,
        itemBuilder: (_, i) {
          final item = items[i];
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: AppColors.creamDark),
              boxShadow: [
                BoxShadow(
                  color: AppColors.maroon.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _PanchangamVectorIcon(
                      iconId: _panchangamIconId(item.label),
                      size: 22,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        item.label,
                        style: const TextStyle(
                          color: Color(0xFF9D174D),
                          fontWeight: FontWeight.w900,
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
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(height: 1.4),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _panchangamIconId(String label) {
    if (label == 'திதி') return 'tithi';
    if (label == 'நட்சத்திரம்') return 'nakshatram';
    if (label == 'யோகம்') return 'yogam';
    if (label == 'கரணம்') return 'karanam';
    if (label.contains('சூரிய')) return 'sunrise';
    if (label.contains('சந்திர')) return 'moonrise';
    return 'dot';
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
                Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.inauspicious,
                  size: 20,
                ),
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
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.inauspicious.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(
                            AppDecorations.cardRadiusSm,
                          ),
                          border: Border.all(
                            color: AppColors.inauspicious.withValues(
                              alpha: 0.2,
                            ),
                          ),
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
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 10,
                              ),
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
            _InfoChip(
              icon: Icons.compass_calibration_rounded,
              text: day.shoolamTa,
            ),
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
        Expanded(
          child: Text(
            text,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(height: 1.4),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: AppCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.info_outline_rounded,
              color: AppColors.maroon,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(height: 1.5),
              ),
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
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
          ),
          itemCount: 16,
          itemBuilder: (_, i) {
            if (i == 5 || i == 6 || i == 9 || i == 10) {
              if (i == 5) {
                return Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: AppColors.maroon.withValues(alpha: 0.08),
                    border: Border.all(
                      color: AppColors.maroon.withValues(alpha: 0.2),
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Text(
                      center,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.maroon,
                      ),
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          const spacing = 10.0;
          final cardWidth = (constraints.maxWidth - spacing) / 2;

          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: items.asMap().entries.map((entry) {
              final h = entry.value;
              final color = _signColors[entry.key % _signColors.length];
              return SizedBox(
                width: cardWidth,
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
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              h.sign,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: color,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        h.prediction,
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(height: 1.4),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        },
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
                Icon(
                  Icons.format_quote_rounded,
                  color: AppColors.goldDark,
                  size: 28,
                ),
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
              child: const Icon(
                Icons.cake_rounded,
                color: AppColors.labelPink,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'பிறந்த நாள்',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    text,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
