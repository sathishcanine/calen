import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/budget.dart';
import '../../services/budget_service.dart';
import '../../theme/budget_theme.dart';
import '../../utils/budget_format.dart';
import 'budget_category_picker_screen.dart';

/// SS2 — transaction entry form (Expense / Income).
class BudgetTransactionEntryScreen extends StatefulWidget {
  const BudgetTransactionEntryScreen({
    super.key,
    required this.type,
    required this.initialDate,
  });

  final BudgetTransactionType type;
  final DateTime initialDate;

  @override
  State<BudgetTransactionEntryScreen> createState() => _BudgetTransactionEntryScreenState();
}

class _BudgetTransactionEntryScreenState extends State<BudgetTransactionEntryScreen> {
  late BudgetTransactionType _type;
  late DateTime _date;
  BudgetCategory? _category;
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _amountFocus = FocusNode();
  bool _isRepeating = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _type = widget.type;
    _date = widget.initialDate;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _amountFocus.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: BudgetColors.brown,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickCategory() async {
    final category = await Navigator.push<BudgetCategory>(
      context,
      MaterialPageRoute(
        builder: (_) => BudgetCategoryPickerScreen(isIncome: _type == BudgetTransactionType.income),
      ),
    );
    if (category != null) setState(() => _category = category);
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0;
    if (_category == null) {
      _showError('Please select a category');
      return;
    }
    if (amount <= 0) {
      _showError('Please enter an amount');
      _amountFocus.requestFocus();
      return;
    }

    setState(() => _saving = true);
    try {
      await BudgetService.instance.addTransaction(
        type: _type,
        categoryId: _category!.id,
        amount: amount,
        date: _date,
        note: _noteController.text,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BudgetColors.formBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            _buildTypeToggle(),
            Expanded(
              child: ListView(
                children: [
                  _FormSection(
                    title: 'Transaction Details',
                    children: [
                      _FormRow(
                        label: 'Date',
                        value: BudgetFormat.shortDate(_date),
                        onTap: _pickDate,
                      ),
                      _FormRow(
                        label: 'Category',
                        value: _category?.name ?? 'Not Selected',
                        placeholder: _category == null,
                        onTap: _pickCategory,
                      ),
                      _FormRow(
                        label: 'Amount',
                        valueWidget: TextField(
                          controller: _amountController,
                          focusNode: _amountFocus,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                          ],
                          decoration: const InputDecoration(
                            isDense: true,
                            hintText: 'Amount',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          style: BudgetTextStyles.formValue(),
                        ),
                        onTap: () => _amountFocus.requestFocus(),
                      ),
                    ],
                  ),
                  _FormSection(
                    title: 'Repeating Details',
                    children: [
                      _FormRow(
                        label: 'Repeat',
                        valueWidget: Switch(
                          value: _isRepeating,
                          onChanged: (v) => setState(() => _isRepeating = v),
                          activeThumbColor: BudgetColors.brown,
                        ),
                      ),
                    ],
                  ),
                  _FormSection(
                    title: '',
                    showHeader: false,
                    children: [
                      _FormRow(
                        label: 'Note',
                        valueWidget: TextField(
                          controller: _noteController,
                          decoration: const InputDecoration(
                            isDense: true,
                            hintText: 'No Note Entered',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          style: BudgetTextStyles.formValue(),
                          textCapitalization: TextCapitalization.sentences,
                          maxLength: 120,
                          buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      color: BudgetColors.headerBg,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          IconButton(
            onPressed: _saving ? null : () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: BudgetColors.brown, size: 26),
          ),
          const Spacer(),
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: BudgetColors.brown),
                  )
                : Text(
                    'Done',
                    style: BudgetTextStyles.header(size: 17, weight: FontWeight.w700),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeToggle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Container(
        decoration: BoxDecoration(
          color: BudgetColors.rowLabelBg,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Expanded(
              child: _TypeTab(
                label: 'EXPENSE',
                selected: _type == BudgetTransactionType.expense,
                onTap: () => setState(() {
                  _type = BudgetTransactionType.expense;
                  _category = null;
                }),
              ),
            ),
            Expanded(
              child: _TypeTab(
                label: 'INCOME',
                selected: _type == BudgetTransactionType.income,
                onTap: () => setState(() {
                  _type = BudgetTransactionType.income;
                  _category = null;
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeTab extends StatelessWidget {
  const _TypeTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? BudgetColors.brown : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: BudgetTextStyles.header(
            size: 13,
            weight: FontWeight.w700,
          ).copyWith(color: selected ? Colors.white : BudgetColors.brown),
        ),
      ),
    );
  }
}

class _FormSection extends StatelessWidget {
  const _FormSection({
    required this.title,
    required this.children,
    this.showHeader = true,
  });

  final String title;
  final List<Widget> children;
  final bool showHeader;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showHeader && title.isNotEmpty)
          Container(
            color: BudgetColors.sectionHeader,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(title, style: BudgetTextStyles.formValue(color: BudgetColors.brownLight)),
                const Spacer(),
                Icon(Icons.help_outline, size: 18, color: BudgetColors.brownLight.withValues(alpha: 0.7)),
              ],
            ),
          ),
        ...children,
      ],
    );
  }
}

class _FormRow extends StatelessWidget {
  const _FormRow({
    required this.label,
    this.value,
    this.valueWidget,
    this.placeholder = false,
    this.onTap,
  });

  final String label;
  final String? value;
  final Widget? valueWidget;
  final bool placeholder;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = valueWidget ??
        Text(
          value ?? '',
          style: BudgetTextStyles.formValue(
            color: placeholder ? BudgetColors.brownLight : BudgetColors.brown,
          ),
        );

    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: BudgetColors.cardBorder, width: 0.5)),
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                Container(
                  width: 110,
                  color: BudgetColors.rowLabelBg,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  alignment: Alignment.centerRight,
                  child: Text(label, style: BudgetTextStyles.formLabel()),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: content,
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
