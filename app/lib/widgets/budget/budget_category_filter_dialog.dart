import 'package:flutter/material.dart';

import '../../models/budget.dart';
import '../../theme/budget_theme.dart';

/// Category filter options — matches SS5 reference.
enum BudgetCategoryFilter {
  allCategories,
  allExpense,
  allIncome,
  allRepeating,
}

class BudgetCategoryFilterSelection {
  const BudgetCategoryFilterSelection(this.filter, [this.categoryId, this._categoryLabel]);

  final BudgetCategoryFilter filter;
  final String? categoryId;
  final String? _categoryLabel;

  String get label {
    final name = _categoryLabel;
    if (name != null) return name;
    return switch (filter) {
      BudgetCategoryFilter.allCategories => 'All Categories',
      BudgetCategoryFilter.allExpense => 'All Expense',
      BudgetCategoryFilter.allIncome => 'All Income',
      BudgetCategoryFilter.allRepeating => 'All Repeating',
    };
  }

  factory BudgetCategoryFilterSelection.category(BudgetCategory category) =>
      BudgetCategoryFilterSelection(BudgetCategoryFilter.allCategories, category.id, category.name);

  bool matches(BudgetTransaction tx) {
    if (categoryId != null) return tx.categoryId == categoryId;
    switch (filter) {
      case BudgetCategoryFilter.allCategories:
        return true;
      case BudgetCategoryFilter.allExpense:
        return tx.type == BudgetTransactionType.expense;
      case BudgetCategoryFilter.allIncome:
        return tx.type == BudgetTransactionType.income;
      case BudgetCategoryFilter.allRepeating:
        return false;
    }
  }
}

/// SS5 — category filter dialog with radio options.
Future<BudgetCategoryFilterSelection?> showBudgetCategoryFilterDialog({
  required BuildContext context,
  required BudgetCategoryFilterSelection current,
  required List<BudgetCategory> categories,
}) {
  return showDialog<BudgetCategoryFilterSelection>(
    context: context,
    builder: (ctx) => _BudgetCategoryFilterDialog(
      current: current,
      categories: categories,
    ),
  );
}

class _BudgetCategoryFilterDialog extends StatefulWidget {
  const _BudgetCategoryFilterDialog({
    required this.current,
    required this.categories,
  });

  final BudgetCategoryFilterSelection current;
  final List<BudgetCategory> categories;

  @override
  State<_BudgetCategoryFilterDialog> createState() => _BudgetCategoryFilterDialogState();
}

class _BudgetCategoryFilterDialogState extends State<_BudgetCategoryFilterDialog> {
  late BudgetCategoryFilterSelection _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.current;
  }

  List<BudgetCategoryFilterSelection> get _options {
    final options = <BudgetCategoryFilterSelection>[
      const BudgetCategoryFilterSelection(BudgetCategoryFilter.allCategories),
      const BudgetCategoryFilterSelection(BudgetCategoryFilter.allExpense),
      const BudgetCategoryFilterSelection(BudgetCategoryFilter.allIncome),
      const BudgetCategoryFilterSelection(BudgetCategoryFilter.allRepeating),
    ];

    final sorted = [...widget.categories]..sort((a, b) => a.name.compareTo(b.name));
    for (final cat in sorted) {
      options.add(BudgetCategoryFilterSelection.category(cat));
    }
    return options;
  }

  bool _isSelected(BudgetCategoryFilterSelection option) {
    if (_selected.categoryId != null || option.categoryId != null) {
      return _selected.categoryId == option.categoryId;
    }
    return _selected.filter == option.filter;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Text(
              'Category Filter',
              style: BudgetTextStyles.header(size: 18, weight: FontWeight.w700),
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                children: _options.map((option) {
                  final selected = _isSelected(option);
                  return InkWell(
                    onTap: () {
                      setState(() => _selected = option);
                      Navigator.pop(context, option);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Row(
                        children: [
                          Icon(
                            selected ? Icons.radio_button_checked : Icons.radio_button_off,
                            color: BudgetColors.brown,
                            size: 22,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(option.label, style: BudgetTextStyles.formValue()),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(
                    context,
                    const BudgetCategoryFilterSelection(BudgetCategoryFilter.allCategories),
                  ),
                  child: Text(
                    'CLEAR FILTER',
                    style: BudgetTextStyles.header(size: 13, weight: FontWeight.w600),
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'CANCEL',
                    style: BudgetTextStyles.header(size: 13, weight: FontWeight.w600),
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
