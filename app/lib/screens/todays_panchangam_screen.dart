import 'package:flutter/material.dart';

import '../models/daily_calendar.dart';
import '../services/calendar_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/native_ad_widget.dart';

/// Competitor-style "இன்றைய பஞ்சாங்கம்" screen (dedicated panchangam view).
class TodaysPanchangamScreen extends StatefulWidget {
  const TodaysPanchangamScreen({
    super.key,
    required this.repository,
    required this.initialDate,
  });

  final CalendarRepository repository;
  final DateTime initialDate;

  @override
  State<TodaysPanchangamScreen> createState() => _TodaysPanchangamScreenState();
}

class _TodaysPanchangamScreenState extends State<TodaysPanchangamScreen> {
  static const _teal = Color(0xFF10B894);

  late DateTime _date;
  DailyCalendar? _day;
  bool _loading = true;
  String? _error;

  final _scrollController = ScrollController();
  final _horoscopeKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _date = widget.initialDate;
    _load();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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

  void _scrollToHoroscope() {
    final ctx = _horoscopeKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  String? _panchangamValue(DailyCalendar day, String label) {
    for (final item in day.panchangam) {
      if (item.label == label) return item.value;
    }
    return null;
  }

  List<PanchangamItem> _detailRows(DailyCalendar day) {
    const order = ['திதி', 'நட்சத்திரம்', 'நாமயோகம்', 'கரணம்', 'சந்திராஷ்டமம்'];
    final rows = <PanchangamItem>[];
    for (final label in order) {
      final value = _panchangamValue(day, label);
      if (value != null && value.isNotEmpty) {
        rows.add(PanchangamItem(label: label, value: value));
      }
    }
    for (final item in day.panchangam) {
      if (!order.contains(item.label) &&
          item.label != 'சூரிய உதயம்' &&
          item.label != 'கரணன்' &&
          !rows.any((r) => r.label == item.label)) {
        rows.add(item);
      }
    }
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const NativeAdWidget(),
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
        title: const Text('இன்றைய பஞ்சாங்கம்'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {},
            tooltip: 'பகிர்',
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today_outlined),
            onPressed: () => _shift(0),
            tooltip: 'இன்று',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _teal))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton(onPressed: _load, child: const Text('மீண்டும் முயற்சி')),
                      ],
                    ),
                  ),
                )
              : _day == null
                  ? const SizedBox.shrink()
                  : ListView(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                      children: [
                        _DateBanner(
                          day: _day!,
                          onPrev: () => _shift(-1),
                          onNext: () => _shift(1),
                        ),
                        const SizedBox(height: 12),
                        _InfoCardsRow(day: _day!),
                        const SizedBox(height: 12),
                        _CtaButton(onTap: _scrollToHoroscope),
                        const SizedBox(height: 12),
                        _PanchangamDetailsCard(rows: _detailRows(_day!)),
                        const SizedBox(height: 12),
                        _SectionCard(
                          title: 'ராசி கட்டம்',
                          child: _RasiChartGrid(
                            cells: _day!.rasiChart,
                            center: _day!.rasiCenterTa,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _SectionCard(
                          title: 'நல்ல நேரம்',
                          child: _TimeTable(slots: _day!.nallaNeram),
                        ),
                        const SizedBox(height: 12),
                        _SectionCard(
                          title: 'கௌரி நல்ல நேரம்',
                          child: _TimeTable(slots: _day!.gowriNallaNeram),
                        ),
                        const SizedBox(height: 12),
                        _HoraPlaceholder(),
                        const SizedBox(height: 12),
                        _InauspiciousCard(day: _day!),
                        const SizedBox(height: 12),
                        _SectionCard(
                          key: _horoscopeKey,
                          title: 'இன்றைய ராசிபலன்',
                          child: _HoroscopeTable(items: _day!.horoscope),
                        ),
                        if (_day!.noteTa.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _NoteCard(text: _day!.noteTa),
                        ],
                      ],
                    ),
    );
  }
}

class _DateBanner extends StatelessWidget {
  const _DateBanner({
    required this.day,
    required this.onPrev,
    required this.onNext,
  });

  final DailyCalendar day;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE91E8C),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            day.monthLabelTa,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _RoundNav(icon: Icons.chevron_left, onTap: onPrev),
              const SizedBox(width: 12),
              Text(
                day.gregorianDisplay,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(width: 12),
              _RoundNav(icon: Icons.chevron_right, onTap: onNext),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            day.subtitleLine1Ta,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70),
          ),
          if (day.subtitleLine2Ta.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              day.subtitleLine2Ta,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RoundNav extends StatelessWidget {
  const _RoundNav({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.2),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}

class _InfoCardsRow extends StatelessWidget {
  const _InfoCardsRow({required this.day});

  final DailyCalendar day;

  String? _findSunrise() {
    for (final item in day.panchangam) {
      if (item.label == 'சூரிய உதயம்') return item.value;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final monthParts = day.monthLabelTa.split(' - ');
    final month = monthParts.isNotEmpty ? monthParts[0] : day.monthLabelTa;
    final weekday = monthParts.length > 1 ? monthParts[1] : '';

    final yearParts = day.subtitleLine2Ta.split(' - ');
    final yearName = yearParts.isNotEmpty ? yearParts[0] : '';
    final tamilDate = yearParts.length > 1 ? yearParts.sublist(1).join(' - ') : day.subtitleLine2Ta;

    final sunrise = _findSunrise() ?? '—';

    return Row(
      children: [
        Expanded(
          child: _MiniInfoCard(
            color: const Color(0xFF4CAF50),
            icon: Icons.calendar_month_rounded,
            line1: month,
            line2: weekday,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MiniInfoCard(
            color: const Color(0xFFE91E63),
            icon: Icons.temple_hindu_rounded,
            line1: yearName,
            line2: tamilDate,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MiniInfoCard(
            color: const Color(0xFF2196F3),
            icon: Icons.wb_sunny_rounded,
            line1: 'சூரிய உதயம்',
            line2: sunrise,
          ),
        ),
      ],
    );
  }
}

class _MiniInfoCard extends StatelessWidget {
  const _MiniInfoCard({
    required this.color,
    required this.icon,
    required this.line1,
    required this.line2,
  });

  final Color color;
  final IconData icon;
  final String line1;
  final String line2;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 26),
          const SizedBox(height: 6),
          Text(
            line1,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 11),
          ),
          const SizedBox(height: 2),
          Text(
            line2,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _CtaButton extends StatelessWidget {
  const _CtaButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF1565C0),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: const Text('இன்றைய நாள் எப்படி உள்ளது?'),
      ),
    );
  }
}

class _PanchangamDetailsCard extends StatelessWidget {
  const _PanchangamDetailsCard({required this.rows});

  final List<PanchangamItem> rows;

  static const _iconColors = {
    'திதி': Color(0xFF00897B),
    'நட்சத்திரம்': Color(0xFFFF9800),
    'நாமயோகம்': Color(0xFFE53935),
    'கரணம்': Color(0xFF7B1FA2),
    'சந்திராஷ்டமம்': Color(0xFF1565C0),
  };

  static const _icons = {
    'திதி': Icons.brightness_2_outlined,
    'நட்சத்திரம்': Icons.star_outline_rounded,
    'நாமயோகம்': Icons.wb_sunny_outlined,
    'கரணம்': Icons.change_history_outlined,
    'சந்திராஷ்டமம்': Icons.public_outlined,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: rows.asMap().entries.map((entry) {
          final item = entry.value;
          final isLast = entry.key == rows.length - 1;
          final color = _iconColors[item.label] ?? const Color(0xFF607D8B);
          final icon = _icons[item.label] ?? Icons.info_outline_rounded;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: Text(
                        item.label,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),
                    Expanded(
                      flex: 5,
                      child: Text(
                        ': ${item.value}',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast) const _DashedDivider(),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    super.key,
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            color: const Color(0xFF10B894),
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _TimeTable extends StatelessWidget {
  const _TimeTable({required this.slots});

  final List<TimeSlot> slots;

  @override
  Widget build(BuildContext context) {
    if (slots.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('தகவல் இல்லை', textAlign: TextAlign.center),
      );
    }

    return Column(
      children: slots.asMap().entries.map((entry) {
        final slot = entry.value;
        final isLast = entry.key == slots.length - 1;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(slot.period, style: const TextStyle(fontWeight: FontWeight.w500)),
                  Text(slot.time, style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            if (!isLast) const _DashedDivider(),
          ],
        );
      }).toList(),
    );
  }
}

class _HoraPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            color: const Color(0xFF10B894),
            child: const Text(
              'ஓரை',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'கிரக ஓரை தகவல் விரைவில் சேர்க்கப்படும்',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {},
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF5D1F0E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('கிரக ஓரை பற்றி மேலும் அறிய'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InauspiciousCard extends StatelessWidget {
  const _InauspiciousCard({required this.day});

  final DailyCalendar day;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF10B894).withValues(alpha: 0.4)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFF10B894), width: 1)),
            ),
            child: Row(
              children: day.inauspicious
                  .map(
                    (s) => Expanded(
                      child: Text(
                        s.name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF10B894),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          if (day.inauspicious.isNotEmpty)
            Row(
              children: day.inauspicious
                  .map(
                    (s) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                        child: Text(
                          s.time,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          if (day.shoolamTa.isNotEmpty || day.pariharamTa.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Row(
                children: [
                  if (day.shoolamTa.isNotEmpty)
                    Expanded(child: Text(day.shoolamTa, style: const TextStyle(fontSize: 12))),
                  if (day.pariharamTa.isNotEmpty)
                    Expanded(child: Text(day.pariharamTa, textAlign: TextAlign.end, style: const TextStyle(fontSize: 12))),
                ],
              ),
            ),
          if (day.lagnamTa.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Text(day.lagnamTa, style: const TextStyle(fontSize: 12)),
            ),
        ],
      ),
    );
  }
}

class _RasiChartGrid extends StatelessWidget {
  const _RasiChartGrid({required this.cells, required this.center});

  final List<String?> cells;
  final String center;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4),
        itemCount: 16,
        itemBuilder: (_, i) {
          if (i == 5 || i == 6 || i == 9 || i == 10) {
            if (i == 5) {
              return Container(
                margin: const EdgeInsets.all(1),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.gold, width: 1.5),
                ),
                child: Center(
                  child: Text(
                    center,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          }
          final text = i < cells.length ? cells[i] : null;
          return Container(
            margin: const EdgeInsets.all(1),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.gold, width: 1),
            ),
            alignment: Alignment.center,
            child: Text(text ?? '', style: const TextStyle(fontSize: 10)),
          );
        },
      ),
    );
  }
}

class _HoroscopeTable extends StatelessWidget {
  const _HoroscopeTable({required this.items});

  final List<HoroscopeItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('தகவல் இல்லை', textAlign: TextAlign.center),
      );
    }

    return Table(
      border: TableBorder.all(color: const Color(0xFF10B894).withValues(alpha: 0.35)),
      children: [
        for (var row = 0; row < (items.length / 4).ceil(); row++)
          TableRow(
            children: [
              for (var col = 0; col < 4; col++)
                _horoscopeCell(row * 4 + col < items.length ? items[row * 4 + col] : null),
            ],
          ),
      ],
    );
  }

  Widget _horoscopeCell(HoroscopeItem? item) {
    if (item == null) return const SizedBox(height: 52);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            item.sign,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          ),
          const SizedBox(height: 4),
          Text(
            item.prediction,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(text, style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.5)),
    );
  }
}

class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: LayoutBuilder(
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
                color: Colors.grey.shade400,
              );
            }),
          );
        },
      ),
    );
  }
}
