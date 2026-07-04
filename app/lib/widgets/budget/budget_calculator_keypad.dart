import 'package:flutter/material.dart';

import '../../theme/budget_theme.dart';

class BudgetCalculatorKeypad extends StatelessWidget {
  const BudgetCalculatorKeypad({
    super.key,
    required this.onKey,
  });

  final ValueChanged<String> onKey;

  static const _keys = [
    ['1', '2', '3', '+'],
    ['4', '5', '6', '-'],
    ['7', '8', '9', '×'],
    ['.', '0', '=', '÷'],
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _keys.map((row) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: row.map((key) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _KeyButton(label: key, onTap: () => onKey(key)),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}

class _KeyButton extends StatelessWidget {
  const _KeyButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  bool get _isOperator => label == '+' || label == '-' || label == '×' || label == '÷' || label == '=';

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Ink(
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: BudgetColors.primaryLight, width: 1.2),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: _isOperator ? 22 : 20,
                fontWeight: FontWeight.w600,
                color: BudgetColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
