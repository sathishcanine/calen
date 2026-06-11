import 'package:flutter/material.dart';

import '../models/hora_week.dart';
import '../services/calendar_repository.dart';
import '../theme/app_theme.dart';

/// கிரக ஓரைகளின் காலம் — weekly planetary hora (Sun–Sat).
class HoraWeekScreen extends StatefulWidget {
  const HoraWeekScreen({
    super.key,
    required this.repository,
    required this.initialDate,
  });

  final CalendarRepository repository;
  final DateTime initialDate;

  @override
  State<HoraWeekScreen> createState() => _HoraWeekScreenState();
}

class _HoraWeekScreenState extends State<HoraWeekScreen> with SingleTickerProviderStateMixin {
  static const _pink = Color(0xFFE91E8C);

  HoraWeek? _week;
  bool _loading = true;
  String? _error;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final week = await widget.repository.getHoraWeek(widget.initialDate);
      if (mounted) {
        setState(() => _week = week);
        _tabController.index = _initialTabIndex(week);
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  int _initialTabIndex(HoraWeek week) {
    final target = DateTime(
      widget.initialDate.year,
      widget.initialDate.month,
      widget.initialDate.day,
    );
    final idx = week.days.indexWhere(
      (d) =>
          d.gregorianDate.year == target.year &&
          d.gregorianDate.month == target.month &&
          d.gregorianDate.day == target.day,
    );
    if (idx >= 0) return idx;
    return widget.initialDate.weekday % 7;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
        title: const Text('கிரக ஓரைகளின் காலம்'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _pink))
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
              : _week == null
                  ? const SizedBox.shrink()
                  : Column(
                      children: [
                        Material(
                          color: _pink,
                          child: TabBar(
                            controller: _tabController,
                            isScrollable: true,
                            indicator: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            indicatorSize: TabBarIndicatorSize.tab,
                            labelColor: _pink,
                            unselectedLabelColor: Colors.white,
                            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            dividerColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                            tabs: _week!.days.map((d) => Tab(text: d.weekdayTa)).toList(),
                          ),
                        ),
                        Expanded(
                          child: TabBarView(
                            controller: _tabController,
                            children: _week!.days.map((d) => _DayPanel(day: d)).toList(),
                          ),
                        ),
                      ],
                    ),
    );
  }
}

class _DayPanel extends StatelessWidget {
  const _DayPanel({required this.day});

  final HoraWeekDay day;

  static const _infoBlue = Color(0xFF448AFF);
  static const _auspicious = Color(0xFF2E7D32);
  static const _inauspicious = Color(0xFFC62828);

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: _infoBlue,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text(
            '* சூரிய உதயத்தில் இருந்து நேரத்தை கணக்கிட்டு கொள்ளவும்.',
            style: TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, height: 1.5),
                  children: [
                    const TextSpan(
                      text: 'சுப ஓரைகள் : ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text: 'வளர்பிறை சந்திரன், புதன், குரு, சுக்கிரன்',
                      style: TextStyle(color: _auspicious, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              RichText(
                text: TextSpan(
                  style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, height: 1.5),
                  children: [
                    const TextSpan(
                      text: 'அசுப ஓரைகள் : ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text: 'தேய்பிறை சந்திரன், சூரியன், செவ்வாய், சனி',
                      style: TextStyle(color: _inauspicious, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ...day.sections.map((section) => _SectionBlock(section: section)),
      ],
    );
  }
}

class _SectionBlock extends StatelessWidget {
  const _SectionBlock({required this.section});

  final HoraSection section;

  static const _pink = Color(0xFFE91E8C);
  static const _auspicious = Color(0xFF2E7D32);
  static const _inauspicious = Color(0xFFC62828);

  IconData _iconForPeriod(String period) {
    switch (period) {
      case 'காலை':
      case 'பிற்பகல்':
      case 'மாலை':
        return Icons.wb_sunny_outlined;
      case 'இரவு':
        return Icons.nightlight_round;
      case 'நள்ளிரவு':
        return Icons.bedtime_outlined;
      case 'அதிகாலை':
        return Icons.wb_twilight;
      default:
        return Icons.schedule;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: _pink,
              child: Row(
                children: [
                  Icon(_iconForPeriod(section.period), color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    section.period,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            ...section.slots.asMap().entries.map((entry) {
              final slot = entry.value;
              final isLast = entry.key == section.slots.length - 1;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            slot.time,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ),
                        Text(
                          slot.planet,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: slot.auspicious ? _auspicious : _inauspicious,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20),
                      ],
                    ),
                  ),
                  if (!isLast) Divider(height: 1, color: Colors.grey.shade300),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}
