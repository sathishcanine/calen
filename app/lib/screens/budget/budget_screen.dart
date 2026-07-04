import 'package:flutter/material.dart';

import '../../models/budget.dart';
import '../../services/budget_currency_service.dart';
import '../../services/budget_service.dart';
import '../../theme/budget_theme.dart';
import '../../utils/budget_format.dart';
import 'budget_month_screen.dart';

/// Budget home — all 12 months of the current year in a 2-column grid.
class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final int _year = DateTime.now().year;
  List<BudgetMonthSummary>? _months;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    BudgetCurrencyService.instance.ensureInitialized();
    BudgetCurrencyService.instance.selected.addListener(_onCurrencyChanged);
    _load();
  }

  @override
  void dispose() {
    BudgetCurrencyService.instance.selected.removeListener(_onCurrencyChanged);
    super.dispose();
  }

  void _onCurrencyChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      await BudgetService.instance.ensureInitialized();
      await BudgetCurrencyService.instance.ensureInitialized();
      final summaries = await BudgetService.instance.getYearSummaries(_year);
      if (mounted) setState(() => _months = summaries);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openMonth(int month) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => BudgetMonthScreen(year: _year, month: month),
      ),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _months == null) {
      return const SizedBox(
        height: 320,
        child: Center(child: CircularProgressIndicator(color: BudgetColors.primary)),
      );
    }

    final months = _months;
    if (months == null) {
      return const SizedBox(
        height: 120,
        child: Center(child: Text('Unable to load budget data')),
      );
    }

    final now = DateTime.now();
    final yearTotalIncome = months.fold<double>(0, (s, m) => s + m.totalIncome);
    final yearTotalExpense = months.fold<double>(0, (s, m) => s + m.totalExpense);

    return Container(
      decoration: BoxDecoration(
        color: BudgetColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BudgetColors.cardBorder),
      ),
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '$_year வரவு செலவு',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: BudgetColors.primaryDark,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          _YearSummaryStrip(
            income: yearTotalIncome,
            expense: yearTotalExpense,
            balance: yearTotalIncome - yearTotalExpense,
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.55,
            ),
            itemCount: 12,
            itemBuilder: (context, index) {
              final month = index + 1;
              final summary = months[index];
              final isCurrent = now.year == _year && now.month == month;

              return _MonthCard(
                month: month,
                summary: summary,
                isCurrent: isCurrent,
                onTap: () => _openMonth(month),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _YearSummaryStrip extends StatelessWidget {
  const _YearSummaryStrip({
    required this.income,
    required this.expense,
    required this.balance,
  });

  final double income;
  final double expense;
  final double balance;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: BudgetColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: BudgetColors.primaryLight),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SummaryCell(
              label: 'Income',
              value: BudgetFormat.currency(income),
              color: BudgetColors.income,
            ),
          ),
          Container(width: 1, height: 32, color: BudgetColors.primaryLight),
          Expanded(
            child: _SummaryCell(
              label: 'Expense',
              value: BudgetFormat.currency(expense),
              color: BudgetColors.expense,
            ),
          ),
          Container(width: 1, height: 32, color: BudgetColors.primaryLight),
          Expanded(
            child: _SummaryCell(
              label: 'Balance',
              value: BudgetFormat.currency(balance),
              color: balance < 0 ? BudgetColors.expense : BudgetColors.primaryDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCell extends StatelessWidget {
  const _SummaryCell({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: BudgetColors.textSecondary)),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
          ),
        ),
      ],
    );
  }
}

class _MonthCard extends StatelessWidget {
  const _MonthCard({
    required this.month,
    required this.summary,
    required this.isCurrent,
    required this.onTap,
  });

  final int month;
  final BudgetMonthSummary summary;
  final bool isCurrent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasData = summary.hasData;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isCurrent ? BudgetColors.primary : BudgetColors.cardBorder,
              width: isCurrent ? 2 : 1,
            ),
            boxShadow: isCurrent
                ? [
                    BoxShadow(
                      color: BudgetColors.primary.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        BudgetFormat.monthName(month),
                        style: TextStyle(
                          color: BudgetColors.primaryDark,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isCurrent)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: BudgetColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Now',
                          style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                if (hasData) ...[
                  Text(
                    'Income: ${BudgetFormat.currencyCompact(summary.totalIncome)}',
                    style: const TextStyle(
                      color: BudgetColors.income,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Expense: ${BudgetFormat.currencyCompact(summary.totalExpense)}',
                    style: const TextStyle(
                      color: BudgetColors.expenseDark,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ] else
                  const Text(
                    'No entries',
                    style: TextStyle(fontSize: 12, color: BudgetColors.textSecondary),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
