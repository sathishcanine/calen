import 'package:flutter/material.dart';

import '../../theme/budget_theme.dart';
import '../../utils/budget_format.dart';
import 'budget_category_icons.dart';

class BudgetAmountBar extends StatelessWidget {
  const BudgetAmountBar({
    super.key,
    required this.amountText,
    required this.onBackspace,
    this.compact = false,
  });

  final String amountText;
  final VoidCallback onBackspace;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: compact ? 72 : 88,
      decoration: BoxDecoration(
        color: BudgetColors.primary,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: BudgetColors.primary.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const BudgetUtilityIcon(kind: BudgetUtilityIconKind.cash, size: 26),
                const SizedBox(height: 2),
                Text(
                  BudgetFormat.currencyCode(),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 44, color: Colors.white.withValues(alpha: 0.45)),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.center,
                child: Text(
                  amountText,
                  maxLines: 1,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: compact ? 34 : 42,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: onBackspace,
            icon: const BudgetUtilityIcon(kind: BudgetUtilityIconKind.backspace, size: 28),
            splashRadius: 22,
          ),
        ],
      ),
    );
  }
}
