import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../config/ad_config.dart';
import '../models/metal_rates.dart';
import '../services/calendar_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/metal_rates_menu_card.dart';
import '../widgets/native_ad_widget.dart';

class MetalRatesScreen extends StatefulWidget {
  const MetalRatesScreen({super.key, required this.repository});

  final CalendarRepository repository;

  @override
  State<MetalRatesScreen> createState() => _MetalRatesScreenState();
}

class _MetalRatesScreenState extends State<MetalRatesScreen> {
  static const _periods = [
    ('7d', '7 Days'),
    ('30d', '30 Days'),
    ('3m', '3 Months'),
    ('6m', '6 Months'),
  ];

  List<MetalRateCity> _cities = [];
  MetalRates? _data;
  String _cityId = 'chennai';
  String _period = '7d';
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final cities = await widget.repository.getMetalRateCities();
      if (cities.isNotEmpty && !cities.any((c) => c.id == _cityId)) {
        _cityId = cities.first.id;
      }
      final data = await widget.repository.getMetalRates(cityId: _cityId, period: _period);
      if (mounted) {
        setState(() {
          _cities = cities;
          _data = data;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _reloadRates() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await widget.repository.getMetalRates(cityId: _cityId, period: _period);
      if (mounted) setState(() => _data = data);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('தங்கம் & வெள்ளி நிலவரம்'),
        backgroundColor: AppColors.maroonDark,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _error != null && _data == null
          ? _ErrorBody(message: _error!, onRetry: _bootstrap)
          : RefreshIndicator(
              onRefresh: _reloadRates,
              color: AppColors.maroon,
              child: _loading && _data == null
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      children: const [_MetalRatesSkeleton()],
                    )
                  : ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                      children: [
                        if (_loading) const LinearProgressIndicator(minHeight: 2, color: AppColors.gold),
                        _CityPicker(
                          cities: _cities,
                          cityId: _cityId,
                          onChanged: (id) {
                            _cityId = id;
                            _reloadRates();
                          },
                        ),
                        if (_data?.lastUpdated != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'இறுதி புதுப்பிப்பு: ${_formatIst(_data!.lastUpdated!)}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.maroon,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        if (_data != null) ...[
                          _GoldTableCard(
                            title: '22 Carat Gold Rate in ${_data!.cityNameEn} (Today & Yesterday)',
                            gold: _data!.gold22k,
                          ),
                          const SizedBox(height: 16),
                          _GoldTableCard(
                            title: '24 Carat Gold Rate in ${_data!.cityNameEn} (Today & Yesterday)',
                            gold: _data!.gold24k,
                          ),
                          const SizedBox(height: 16),
                          NativeAdWidget(adUnitId: AdConfig.metalRatesNativeUnitId),
                          const SizedBox(height: 16),
                          _RecentDaysCard(
                            cityName: _data!.cityNameEn,
                            rows: _data!.recentDaily,
                          ),
                          const SizedBox(height: 16),
                          _SilverCard(cityName: _data!.cityNameEn, silver: _data!.silver),
                          const SizedBox(height: 16),
                          _PeriodTabs(
                            periods: _periods,
                            selected: _period,
                            onSelected: (p) {
                              _period = p;
                              _reloadRates();
                            },
                          ),
                          const SizedBox(height: 12),
                          _GoldChartCard(
                            title: 'Weekly & Monthly Graph of 22K Gold Rate in ${_data!.cityNameTa} (1 gram)',
                            history: _data!.goldHistory,
                            show24k: false,
                          ),
                          const SizedBox(height: 16),
                          _GoldChartCard(
                            title: 'Gold Rate Weekly Comparison — 22K vs 24K',
                            history: _data!.goldHistory,
                            show24k: true,
                          ),
                        ],
                      ],
                    ),
            ),
    );
  }
}

class _CityPicker extends StatelessWidget {
  const _CityPicker({
    required this.cities,
    required this.cityId,
    required this.onChanged,
  });

  final List<MetalRateCity> cities;
  final String cityId;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: cities.any((c) => c.id == cityId) ? cityId : cities.firstOrNull?.id,
          items: cities
              .map(
                (c) => DropdownMenuItem(
                  value: c.id,
                  child: Text('${c.nameTa} · ${c.nameEn}', style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
              )
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

class _GoldTableCard extends StatelessWidget {
  const _GoldTableCard({required this.title, required this.gold});

  final String title;
  final MetalRateGold gold;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: const Color(0xFF1A237E),
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 12),
          _RatesTable(
            headers: const ['Gram', 'Today', 'Yesterday', 'Change'],
            rows: gold.table
                .map(
                  (r) => [
                    '${r.grams} gram${r.grams > 1 ? 's' : ''}',
                    formatInr(r.today),
                    formatInr(r.yesterday),
                    _ChangeCell(change: r.change),
                  ],
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _SilverCard extends StatelessWidget {
  const _SilverCard({required this.cityName, required this.silver});

  final String cityName;
  final MetalRateSilver silver;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.creamDark,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.textSecondary.withValues(alpha: 0.3)),
                ),
                child: const Icon(Icons.circle, color: Color(0xFF90A4AE), size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                '$cityName Silver Rate — Last 10 days',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.maroon,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _RatesTable(
            headers: const ['Date', 'Silver 1 Gm', 'Ready Silver (1 Kg)'],
            rows: silver.history
                .map(
                  (r) => [
                    formatTableDate(r.date),
                    formatInrDecimal(r.perGram),
                    formatInrDecimal(r.perKg),
                  ],
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _RecentDaysCard extends StatelessWidget {
  const _RecentDaysCard({required this.cityName, required this.rows});

  final String cityName;
  final List<MetalRateRecentDay> rows;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Gold Rate in $cityName for Last 10 days',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: const Color(0xFF1A237E),
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 12),
          _RatesTable(
            headers: const ['Date', 'Standard Gold (22K) (8 grams)', 'Pure Gold (24K) (8 grams)'],
            rows: rows
                .map(
                  (r) => [
                    formatShortDate(r.date),
                    '${formatInr(r.gold22k8g)} ${_changeSuffix(r.change22k8g)}',
                    '${formatInr(r.gold24k8g)} ${_changeSuffix(r.change24k8g)}',
                  ],
                )
                .toList(),
            coloredChanges: true,
          ),
        ],
      ),
    );
  }

  String _changeSuffix(double change) {
    if (change == 0) return '';
    final sign = change > 0 ? '▲' : '▼';
    return '(${formatInr(change.abs())} $sign)';
  }
}

class _ChangeCell extends StatelessWidget {
  const _ChangeCell({required this.change});

  final double change;

  @override
  Widget build(BuildContext context) {
    if (change == 0) {
      return const Text('—', textAlign: TextAlign.center, maxLines: 1);
    }
    final up = change > 0;
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            formatInr(change.abs()),
            style: TextStyle(
              color: up ? AppColors.auspicious : AppColors.inauspicious,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          Icon(
            up ? Icons.arrow_drop_up_rounded : Icons.arrow_drop_down_rounded,
            color: up ? AppColors.auspicious : AppColors.inauspicious,
            size: 18,
          ),
        ],
      ),
    );
  }
}

class _RatesTable extends StatelessWidget {
  const _RatesTable({
    required this.headers,
    required this.rows,
    this.coloredChanges = false,
  });

  final List<String> headers;
  final List<List<Object>> rows;
  final bool coloredChanges;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Table(
        border: TableBorder.all(color: const Color(0xFFE0E0E0)),
        columnWidths: _columnWidths(headers.length),
        children: [
          TableRow(
            decoration: const BoxDecoration(color: Color(0xFF1565C0)),
            children: headers
                .map(
                  (h) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                    child: Text(
                      h,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11),
                    ),
                  ),
                )
                .toList(),
          ),
          ...rows.asMap().entries.map((entry) {
            final i = entry.key;
            final row = entry.value;
            return TableRow(
              decoration: BoxDecoration(color: i.isEven ? Colors.white : const Color(0xFFF5F5F5)),
              children: row
                  .map(
                    (cell) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                      child: cell is Widget
                          ? Align(alignment: Alignment.center, child: cell)
                          : Text(
                              cell.toString(),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: coloredChanges && cell.toString().contains('▲')
                                    ? AppColors.auspicious
                                    : coloredChanges && cell.toString().contains('▼')
                                        ? AppColors.inauspicious
                                        : AppColors.textPrimary,
                              ),
                            ),
                    ),
                  )
                  .toList(),
            );
          }),
        ],
      ),
    );
  }

  Map<int, TableColumnWidth> _columnWidths(int count) {
    if (count == 4) {
      return const {
        0: FlexColumnWidth(0.9),
        1: FlexColumnWidth(1.1),
        2: FlexColumnWidth(1.1),
        3: FlexColumnWidth(1.0),
      };
    }
    return {for (var i = 0; i < count; i++) i: const FlexColumnWidth()};
  }
}

class _PeriodTabs extends StatelessWidget {
  const _PeriodTabs({
    required this.periods,
    required this.selected,
    required this.onSelected,
  });

  final List<(String, String)> periods;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: periods.map((p) {
          final active = p.$1 == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(p.$2),
              selected: active,
              onSelected: (_) => onSelected(p.$1),
              selectedColor: const Color(0xFF1565C0),
              labelStyle: TextStyle(
                color: active ? Colors.white : const Color(0xFF1565C0),
                fontWeight: FontWeight.w700,
              ),
              side: BorderSide(color: const Color(0xFF1565C0).withValues(alpha: active ? 1 : 0.5)),
              backgroundColor: Colors.white,
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _GoldChartCard extends StatelessWidget {
  const _GoldChartCard({
    required this.title,
    required this.history,
    required this.show24k,
  });

  final String title;
  final List<MetalRateGoldHistory> history;
  final bool show24k;

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) return const SizedBox.shrink();

    final spots22 = history.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.gold22k)).toList();
    final spots24 = history.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.gold24k)).toList();
    final allY = [...history.map((e) => e.gold22k), ...history.map((e) => e.gold24k)];
    final minY = allY.reduce((a, b) => a < b ? a : b) * 0.995;
    final maxY = allY.reduce((a, b) => a > b ? a : b) * 1.005;

    String labelFor(int index) {
      if (index < 0 || index >= history.length) return '';
      return formatShortDate(history[index].date);
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: const Color(0xFF1A237E),
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                minY: minY,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(color: Colors.grey.withValues(alpha: 0.2)),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 52,
                      getTitlesWidget: (v, _) => Text(
                        formatInr(v),
                        style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: (history.length / 4).clamp(1, 999).toDouble(),
                      getTitlesWidget: (v, _) {
                        final i = v.round();
                        if (i == 0 || i == history.length - 1 || i == history.length ~/ 2) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(labelFor(i), style: const TextStyle(fontSize: 10)),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots22,
                    isCurved: true,
                    color: show24k ? const Color(0xFF00897B) : const Color(0xFF1565C0),
                    barWidth: 3,
                    dotData: FlDotData(show: history.length <= 12),
                    belowBarData: show24k
                        ? BarAreaData(show: false)
                        : BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF1565C0).withValues(alpha: 0.35),
                                const Color(0xFF1565C0).withValues(alpha: 0.02),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                  ),
                  if (show24k)
                    LineChartBarData(
                      spots: spots24,
                      isCurved: true,
                      color: const Color(0xFFEF6C00),
                      barWidth: 3,
                      dotData: FlDotData(show: history.length <= 12),
                    ),
                ],
              ),
            ),
          ),
          if (show24k) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                _LegendDot(color: const Color(0xFF00897B), label: '22K Gold Rate'),
                const SizedBox(width: 16),
                _LegendDot(color: const Color(0xFFEF6C00), label: '24K Gold Rate'),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _MetalRatesSkeleton extends StatelessWidget {
  const _MetalRatesSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        4,
        (i) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  height: 16,
                  decoration: BoxDecoration(
                    color: AppColors.creamDark,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 12),
                ...List.generate(
                  3,
                  (_) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.creamDark,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.maroon),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('மீண்டும் முயற்சி')),
          ],
        ),
      ),
    );
  }
}

extension _FirstOrNull<E> on List<E> {
  E? get firstOrNull => isEmpty ? null : first;
}

String _formatIst(DateTime value) {
  final utc = value.isUtc ? value : value.toUtc();
  final ist = utc.add(const Duration(hours: 5, minutes: 30));
  return '${DateFormat('dd/MM/yyyy hh:mm a').format(ist)} IST';
}
