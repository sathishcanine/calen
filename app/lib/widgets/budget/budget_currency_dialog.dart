import 'package:flutter/material.dart';

import '../../models/budget_currency.dart';
import '../../services/budget_currency_service.dart';
import '../../theme/budget_theme.dart';
import '../../utils/budget_format.dart';

Future<void> showBudgetCurrencyDialog(BuildContext context) async {
  await showDialog<void>(
    context: context,
    builder: (ctx) => const _BudgetCurrencyDialog(),
  );
}

class _BudgetCurrencyDialog extends StatefulWidget {
  const _BudgetCurrencyDialog();

  @override
  State<_BudgetCurrencyDialog> createState() => _BudgetCurrencyDialogState();
}

class _BudgetCurrencyDialogState extends State<_BudgetCurrencyDialog> {
  late BudgetCurrencyOption _selected;

  @override
  void initState() {
    super.initState();
    _selected = BudgetCurrencyService.instance.selected.value;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: BudgetColors.headerBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text(
        'Currency',
        style: BudgetTextStyles.header(size: 18, weight: FontWeight.w700),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView(
          shrinkWrap: true,
          children: BudgetCurrencies.all.map((option) {
            final active = _selected.id == option.id;
            return RadioListTile<BudgetCurrencyOption>(
              value: option,
              groupValue: _selected,
              activeColor: BudgetColors.brown,
              title: Text(
                option.label,
                style: BudgetTextStyles.formValue(
                  color: active ? BudgetColors.brown : BudgetColors.textPrimary,
                ),
              ),
              subtitle: Text(
                '${option.symbol}  ${option.code}  ·  ${BudgetFormat.currencyWith(option, 1234.56)}',
                style: BudgetTextStyles.formValue(color: BudgetColors.brownLight),
              ),
              onChanged: (value) {
                if (value == null) return;
                setState(() => _selected = value);
              },
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: BudgetTextStyles.formValue()),
        ),
        TextButton(
          onPressed: () async {
            await BudgetCurrencyService.instance.setCurrency(_selected);
            if (context.mounted) Navigator.pop(context);
          },
          child: Text(
            'Apply',
            style: BudgetTextStyles.header(size: 14, weight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
