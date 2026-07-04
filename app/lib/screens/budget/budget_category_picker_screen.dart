import 'package:flutter/material.dart';

import '../../models/budget.dart';
import '../../services/budget_service.dart';
import '../../theme/budget_theme.dart';
import '../../widgets/budget/budget_list_category_icon.dart';

/// SS3 — searchable category list for transaction entry.
class BudgetCategoryPickerScreen extends StatefulWidget {
  const BudgetCategoryPickerScreen({
    super.key,
    required this.isIncome,
  });

  final bool isIncome;

  @override
  State<BudgetCategoryPickerScreen> createState() => _BudgetCategoryPickerScreenState();
}

class _BudgetCategoryPickerScreenState extends State<BudgetCategoryPickerScreen> {
  final _searchController = TextEditingController();
  List<BudgetCategory> _categories = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      await BudgetService.instance.ensureInitialized();
      final categories = widget.isIncome
          ? await BudgetService.instance.getIncomeCategories()
          : await BudgetService.instance.getExpenseCategories();
      if (mounted) setState(() => _categories = categories);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<BudgetCategory> get _filtered {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _categories;
    return _categories.where((c) => c.name.toLowerCase().contains(query)).toList();
  }

  Future<void> _addCategory() async {
    final name = _searchController.text.trim();
    if (name.isEmpty) return;

    try {
      final category = await BudgetService.instance.addCustomCategory(
        name: name,
        isIncome: widget.isIncome,
      );
      if (mounted) Navigator.pop(context, category);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final query = _searchController.text.trim();
    final showAdd = query.isNotEmpty && !filtered.any((c) => c.name.toLowerCase() == query.toLowerCase());

    return Scaffold(
      backgroundColor: BudgetColors.formBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              color: BudgetColors.headerBg,
              padding: const EdgeInsets.fromLTRB(4, 8, 16, 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: BudgetColors.brown),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: 'Search or add a category',
                        hintStyle: BudgetTextStyles.formValue(color: BudgetColors.brownLight),
                        prefixIcon: const Icon(Icons.search, color: BudgetColors.brownLight, size: 22),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      style: BudgetTextStyles.formValue(),
                      textCapitalization: TextCapitalization.words,
                      onSubmitted: showAdd ? (_) => _addCategory() : null,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: BudgetColors.cardBorder),
            if (_loading)
              const Expanded(child: Center(child: CircularProgressIndicator(color: BudgetColors.brown)))
            else
              Expanded(
                child: ListView.separated(
                  itemCount: filtered.length + (showAdd ? 1 : 0),
                  separatorBuilder: (_, __) => const Divider(height: 1, indent: 56, color: BudgetColors.cardBorder),
                  itemBuilder: (context, index) {
                    if (showAdd && index == filtered.length) {
                      return ListTile(
                        leading: const Icon(Icons.add, color: BudgetColors.brown),
                        title: Text('Add "$query"', style: BudgetTextStyles.transactionTitle()),
                        onTap: _addCategory,
                      );
                    }
                    final category = filtered[index];
                    return ListTile(
                      leading: BudgetListCategoryIcon(kind: category.kind),
                      title: Text(category.name, style: BudgetTextStyles.transactionTitle()),
                      onTap: () => Navigator.pop(context, category),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
