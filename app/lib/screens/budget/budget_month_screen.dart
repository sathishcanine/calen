import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/ad_config.dart';
import '../../models/budget.dart';
import '../../services/ad_service.dart';
import '../../services/budget_currency_service.dart';
import '../../services/budget_export_service.dart';
import '../../services/budget_rating_service.dart';
import '../../services/budget_service.dart';
import '../../theme/budget_theme.dart';
import '../../utils/app_share.dart';
import '../../utils/budget_format.dart';
import '../../widgets/budget/budget_category_filter_dialog.dart';
import '../../widgets/budget/budget_currency_dialog.dart';
import '../../widgets/budget/budget_list_category_icon.dart';
import '../../widgets/budget/budget_rating_dialog.dart';
import '../../widgets/native_ad_widget.dart';
import 'budget_transaction_entry_screen.dart';

enum BudgetHubTab { spending, transactions, categories }

/// Standalone monthly budget hub — SS1 spending, SS4 transactions.
class BudgetMonthScreen extends StatefulWidget {
  const BudgetMonthScreen({
    super.key,
    required this.year,
    required this.month,
  });

  final int year;
  final int month;

  @override
  State<BudgetMonthScreen> createState() => _BudgetMonthScreenState();
}

class _BudgetMonthScreenState extends State<BudgetMonthScreen> {
  BudgetMonthSummary? _summary;
  List<BudgetCategory> _allCategories = [];
  bool _loading = true;
  BudgetHubTab _tab = BudgetHubTab.spending;
  BudgetCategoryFilterSelection _filter = const BudgetCategoryFilterSelection(BudgetCategoryFilter.allCategories);

  int get _year => widget.year;
  int get _month => widget.month;

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

  Future<void> _showCurrencyPicker() => showBudgetCurrencyDialog(context);

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      await BudgetService.instance.ensureInitialized();
      await BudgetCurrencyService.instance.ensureInitialized();
      final results = await Future.wait([
        BudgetService.instance.getMonthSummary(_year, _month),
        BudgetService.instance.getAllCategories(),
      ]);
      if (mounted) {
        setState(() {
          _summary = results[0] as BudgetMonthSummary;
          _allCategories = results[1] as List<BudgetCategory>;
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openPlayStore() async {
    final uri = Uri.parse(AppShare.playStoreUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _handleBack() async {
    final hasRated = await BudgetRatingService.instance.hasAcceptedRating();
    if (!hasRated) {
      if (!mounted) return;
      final choice = await showBudgetRatingDialog(context);
      if (!mounted) return;
      if (choice == BudgetRatingChoice.yes) {
        await BudgetRatingService.instance.markRatingAccepted();
        await _openPlayStore();
      } else if (choice == BudgetRatingChoice.maybe && mounted) {
        Navigator.pop(context);
      }
      return;
    }

    if (!mounted) return;
    await AdService.instance.showInterstitialForUnit(
      adUnitId: AdConfig.budgetInterstitialUnitId,
      onFinished: () {
        if (mounted) Navigator.pop(context);
      },
    );
  }

  Future<void> _changeMonth(int delta) async {
    var month = _month + delta;
    var year = _year;
    if (month < 1) {
      month = 12;
      year--;
    } else if (month > 12) {
      month = 1;
      year++;
    }
    if (!mounted) return;
    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => BudgetMonthScreen(year: year, month: month)),
    );
  }

  Future<void> _openEntry(BudgetTransactionType type) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => BudgetTransactionEntryScreen(
          type: type,
          initialDate: DateTime(_year, _month, DateTime.now().day),
        ),
      ),
    );
    if (saved == true) await _load();
  }

  Future<void> _showFilter() async {
    final result = await showBudgetCategoryFilterDialog(
      context: context,
      current: _filter,
      categories: _allCategories,
    );
    if (result != null) setState(() => _filter = result);
  }

  Future<void> _exportMonth() async {
    final summary = _summary;
    if (summary == null) return;

    try {
      await BudgetExportService.instance.exportMonth(
        year: _year,
        month: _month,
        summary: summary,
        categoryMap: _categoryMap,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Map<String, BudgetCategory> get _categoryMap => {for (final c in _allCategories) c.id: c};

  List<BudgetTransaction> get _filteredTransactions {
    final summary = _summary;
    if (summary == null) return [];
    return summary.allTransactions.where(_filter.matches).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleBack();
      },
      child: Scaffold(
        backgroundColor: BudgetColors.headerBg,
        bottomNavigationBar: NativeAdWidget(adUnitId: AdConfig.budgetNativeUnitId),
        body: SafeArea(
          child: _loading && _summary == null
              ? const Center(child: CircularProgressIndicator(color: BudgetColors.brown))
              : Column(
                  children: [
                    _BudgetHubHeader(
                      month: _month,
                      tab: _tab,
                      onTabChanged: (t) => setState(() => _tab = t),
                      onBack: _handleBack,
                      onPrevMonth: () => _changeMonth(-1),
                      onNextMonth: () => _changeMonth(1),
                      showTransactionActions: _tab == BudgetHubTab.transactions,
                      onAdd: () => _showEntryTypePicker(),
                      onFilter: _showFilter,
                      onExport: _exportMonth,
                      onCurrency: _showCurrencyPicker,
                    ),
                    Expanded(child: _buildBody()),
                  ],
                ),
        ),
      ),
    );
  }

  Future<void> _showEntryTypePicker() async {
    final type = await showModalBottomSheet<BudgetTransactionType>(
      context: context,
      backgroundColor: BudgetColors.headerBg,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('+ Expense', style: BudgetTextStyles.header()),
              onTap: () => Navigator.pop(ctx, BudgetTransactionType.expense),
            ),
            ListTile(
              title: Text('+ Income', style: BudgetTextStyles.header()),
              onTap: () => Navigator.pop(ctx, BudgetTransactionType.income),
            ),
          ],
        ),
      ),
    );
    if (type != null) await _openEntry(type);
  }

  Widget _buildBody() {
    final summary = _summary;
    if (summary == null) {
      return const Center(child: Text('Unable to load budget data'));
    }

    return switch (_tab) {
      BudgetHubTab.spending => _SpendingTab(
          summary: summary,
          onExpense: () => _openEntry(BudgetTransactionType.expense),
          onIncome: () => _openEntry(BudgetTransactionType.income),
        ),
      BudgetHubTab.transactions => _TransactionsTab(
          summary: summary,
          transactions: _filteredTransactions,
          categoryMap: _categoryMap,
          filterLabel: _filter.label,
          onFilterTap: _showFilter,
        ),
      BudgetHubTab.categories => _CategoriesTab(summary: summary),
    };
  }
}

// ─── Header + tab bar ────────────────────────────────────────────────────────

class _BudgetHubHeader extends StatelessWidget {
  const _BudgetHubHeader({
    required this.month,
    required this.tab,
    required this.onTabChanged,
    required this.onBack,
    required this.onPrevMonth,
    required this.onNextMonth,
    required this.showTransactionActions,
    required this.onAdd,
    required this.onFilter,
    required this.onExport,
    required this.onCurrency,
  });

  final int month;
  final BudgetHubTab tab;
  final ValueChanged<BudgetHubTab> onTabChanged;
  final VoidCallback onBack;
  final VoidCallback onPrevMonth;
  final VoidCallback onNextMonth;
  final bool showTransactionActions;
  final VoidCallback onAdd;
  final VoidCallback onFilter;
  final VoidCallback onExport;
  final VoidCallback onCurrency;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back, color: BudgetColors.brown, size: 22),
                    visualDensity: VisualDensity.compact,
                  ),
                  const Spacer(),
                  if (showTransactionActions)
                    IconButton(
                      onPressed: onAdd,
                      icon: const Icon(Icons.add, color: BudgetColors.brown),
                    ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: BudgetColors.brown),
                    onSelected: (v) {
                      if (v == 'currency') onCurrency();
                      if (v == 'filter') onFilter();
                      if (v == 'export') onExport();
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'currency', child: Text('Currency')),
                      const PopupMenuItem(value: 'export', child: Text('Export')),
                      if (showTransactionActions)
                        const PopupMenuItem(value: 'filter', child: Text('Category Filter')),
                    ],
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: onPrevMonth,
                    icon: const Icon(Icons.chevron_left, color: BudgetColors.brown, size: 28),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  ),
                  _MonthChip(label: BudgetFormat.monthName(month)),
                  IconButton(
                    onPressed: onNextMonth,
                    icon: const Icon(Icons.chevron_right, color: BudgetColors.brown, size: 28),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        _TabBar(tab: tab, onTabChanged: onTabChanged),
      ],
    );
  }
}

class _MonthChip extends StatelessWidget {
  const _MonthChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: BudgetColors.brown, width: 1.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: BudgetTextStyles.header(size: 15)),
    );
  }
}

class _TabBar extends StatelessWidget {
  const _TabBar({required this.tab, required this.onTabChanged});

  final BudgetHubTab tab;
  final ValueChanged<BudgetHubTab> onTabChanged;

  static const _tabs = [
    (BudgetHubTab.spending, 'Spending', Icons.sell_outlined),
    (BudgetHubTab.transactions, 'Transactions', Icons.menu_book_outlined),
    (BudgetHubTab.categories, 'Categories', Icons.inventory_2_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _tabs.map((entry) {
        final (t, label, icon) = entry;
        final active = tab == t;
        return Expanded(
          child: GestureDetector(
            onTap: () => onTabChanged(t),
            behavior: HitTestBehavior.opaque,
            child: Column(
              children: [
                Icon(icon, size: 22, color: BudgetColors.brown),
                const SizedBox(height: 2),
                Text(label, style: BudgetTextStyles.tabLabel(active: active)),
                const SizedBox(height: 4),
                Container(
                  height: 3,
                  color: active ? BudgetColors.brown : Colors.transparent,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── SS1 Spending tab ────────────────────────────────────────────────────────

class _SpendingTab extends StatelessWidget {
  const _SpendingTab({
    required this.summary,
    required this.onExpense,
    required this.onIncome,
  });

  final BudgetMonthSummary summary;
  final VoidCallback onExpense;
  final VoidCallback onIncome;

  @override
  Widget build(BuildContext context) {
    final income = summary.totalIncome;
    final expense = summary.totalExpense;
    final balance = summary.balance;
    final expenseRatio = income > 0 ? (expense / income).clamp(0.0, 1.0) : 0.0;

    return Column(
      children: [
        Expanded(
          child: Container(
            color: BudgetColors.chalkboard,
            width: double.infinity,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _BudgetProgressBar(expenseRatio: expenseRatio),
                  const SizedBox(height: 28),
                  _ChalkAmountRow(
                    label: 'Income',
                    amount: BudgetFormat.currency(income),
                    amountColor: BudgetColors.chalkIncome,
                    labelSize: 23,
                    amountSize: 23,
                  ),
                  const SizedBox(height: 16),
                  _ChalkAmountRow(
                    label: 'Expense',
                    amount: BudgetFormat.currency(expense),
                    amountColor: BudgetColors.chalkExpense,
                    labelSize: 23,
                    amountSize: 23,
                  ),
                  if (summary.expenseByCategory.where((e) => e.total > 0).isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ...summary.expenseByCategory.where((e) => e.total > 0).map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: _ChalkAmountRow(
                              label: item.category.name,
                              amount: BudgetFormat.currency(item.total),
                              amountColor: BudgetColors.chalkWhite,
                              labelSize: 17,
                              amountSize: 17,
                              indent: 24,
                            ),
                          ),
                        ),
                  ],
                  const SizedBox(height: 20),
                  _DashedDivider(),
                  const SizedBox(height: 16),
                  _ChalkAmountRow(
                    label: 'Balance',
                    amount: '${balance >= 0 ? '+' : ''}${BudgetFormat.currency(balance)}',
                    amountColor: BudgetColors.chalkBalance,
                    labelSize: 23,
                    amountSize: 23,
                  ),
                ],
              ),
            ),
          ),
        ),
        Container(
          color: BudgetColors.chalkboard,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Row(
            children: [
              Expanded(child: _ChalkButton(label: '+ Expense', onTap: onExpense)),
              const SizedBox(width: 16),
              Expanded(child: _ChalkButton(label: '+ Income', onTap: onIncome)),
            ],
          ),
        ),
      ],
    );
  }
}

class _BudgetProgressBar extends StatelessWidget {
  const _BudgetProgressBar({required this.expenseRatio});

  final double expenseRatio;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        height: 22,
        child: Row(
          children: [
            Expanded(
              flex: ((1 - expenseRatio) * 100).round().clamp(1, 100),
              child: Container(color: BudgetColors.progressGreen),
            ),
            Expanded(
              flex: (expenseRatio * 100).round().clamp(expenseRatio > 0 ? 1 : 0, 100),
              child: Container(color: BudgetColors.progressRed),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChalkAmountRow extends StatelessWidget {
  const _ChalkAmountRow({
    required this.label,
    required this.amount,
    required this.amountColor,
    this.labelSize = 23,
    this.amountSize = 23,
    this.indent = 0,
  });

  final String label;
  final String amount;
  final Color amountColor;
  final double labelSize;
  final double amountSize;
  final double indent;

  static const _tabular = [FontFeature.tabularFigures()];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: indent),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Expanded(
            child: Text(
              label,
              style: BudgetTextStyles.chalk(size: labelSize),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            amount,
            textAlign: TextAlign.right,
            style: BudgetTextStyles.chalk(size: amountSize, color: amountColor).copyWith(
              fontFeatures: _tabular,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const dashWidth = 6.0;
        const dashSpace = 4.0;
        final count = (constraints.maxWidth / (dashWidth + dashSpace)).floor();
        return Row(
          children: List.generate(count, (i) {
            return Padding(
              padding: const EdgeInsets.only(right: dashSpace),
              child: Container(width: dashWidth, height: 1.5, color: BudgetColors.chalkWhite.withValues(alpha: 0.6)),
            );
          }),
        );
      },
    );
  }
}

class _ChalkButton extends StatelessWidget {
  const _ChalkButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: BudgetColors.chalkWhite, width: 1.5),
          borderRadius: BorderRadius.circular(4),
        ),
        alignment: Alignment.center,
        child: Text(label, style: BudgetTextStyles.chalk(size: 18)),
      ),
    );
  }
}

// ─── SS4 Transactions tab ─────────────────────────────────────────────────────

class _TransactionsTab extends StatelessWidget {
  const _TransactionsTab({
    required this.summary,
    required this.transactions,
    required this.categoryMap,
    required this.filterLabel,
    required this.onFilterTap,
  });

  final BudgetMonthSummary summary;
  final List<BudgetTransaction> transactions;
  final Map<String, BudgetCategory> categoryMap;
  final String filterLabel;
  final VoidCallback onFilterTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                color: BudgetColors.incomeSummaryBg,
                padding: const EdgeInsets.symmetric(vertical: 14),
                alignment: Alignment.center,
                child: Text(
                  BudgetFormat.currency(summary.totalIncome),
                  style: BudgetTextStyles.header(size: 16, weight: FontWeight.w700)
                      .copyWith(color: BudgetColors.incomeText),
                ),
              ),
            ),
            Expanded(
              child: Container(
                color: BudgetColors.expenseSummaryBg,
                padding: const EdgeInsets.symmetric(vertical: 14),
                alignment: Alignment.center,
                child: Text(
                  BudgetFormat.currency(summary.totalExpense),
                  style: BudgetTextStyles.header(size: 16, weight: FontWeight.w700)
                      .copyWith(color: BudgetColors.expenseText),
                ),
              ),
            ),
          ],
        ),
        Material(
          color: BudgetColors.rowLabelBg,
          child: InkWell(
            onTap: onFilterTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.filter_list, size: 18, color: BudgetColors.brown),
                  const SizedBox(width: 8),
                  Text('Filter: $filterLabel', style: BudgetTextStyles.formValue()),
                  const Spacer(),
                  const Icon(Icons.chevron_right, color: BudgetColors.brownLight, size: 20),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: transactions.isEmpty
              ? Center(
                  child: Text(
                    'No transactions yet.',
                    style: BudgetTextStyles.formValue(color: BudgetColors.brownLight),
                  ),
                )
              : ListView.separated(
                  itemCount: transactions.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: BudgetColors.cardBorder),
                  itemBuilder: (context, index) {
                    final tx = transactions[index];
                    final category = categoryMap[tx.categoryId];
                    final isIncome = tx.type == BudgetTransactionType.income;
                    return ListTile(
                      leading: BudgetListCategoryIcon(kind: category?.kind ?? BudgetCategoryKind.custom),
                      title: Text(
                        category?.name ?? 'Unknown',
                        style: BudgetTextStyles.transactionTitle(),
                      ),
                      subtitle: Text(
                        BudgetFormat.transactionDate(tx.date),
                        style: BudgetTextStyles.transactionDate(),
                      ),
                      trailing: Text(
                        BudgetFormat.currency(tx.amount),
                        style: BudgetTextStyles.header(size: 15, weight: FontWeight.w600).copyWith(
                          color: isIncome ? BudgetColors.incomeText : BudgetColors.expenseText,
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ─── Categories tab ──────────────────────────────────────────────────────────

class _CategoriesTab extends StatelessWidget {
  const _CategoriesTab({required this.summary});

  final BudgetMonthSummary summary;

  @override
  Widget build(BuildContext context) {
    final items = [
      ...summary.incomeByCategory,
      ...summary.expenseByCategory,
    ]..sort((a, b) => b.total.compareTo(a.total));

    if (items.isEmpty) {
      return Center(
        child: Text('No category data yet.', style: BudgetTextStyles.formValue(color: BudgetColors.brownLight)),
      );
    }

    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1, color: BudgetColors.cardBorder),
      itemBuilder: (context, index) {
        final item = items[index];
        final isIncome = item.category.isIncome;
        return ListTile(
          leading: BudgetListCategoryIcon(kind: item.category.kind),
          title: Text(item.category.name, style: BudgetTextStyles.transactionTitle()),
          trailing: Text(
            BudgetFormat.currency(item.total),
            style: BudgetTextStyles.header(size: 14).copyWith(
              color: isIncome ? BudgetColors.incomeText : BudgetColors.expenseText,
            ),
          ),
        );
      },
    );
  }
}
