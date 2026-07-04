import 'package:flutter/material.dart';

import '../../models/budget.dart';
import '../../theme/budget_theme.dart';

/// Silhouette-style category icons for list views (SS3 / SS4).
class BudgetListCategoryIcon extends StatelessWidget {
  const BudgetListCategoryIcon({super.key, required this.kind, this.size = 28});

  final BudgetCategoryKind kind;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Icon(
      _iconForKind(kind),
      size: size,
      color: BudgetColors.brown,
    );
  }

  static IconData _iconForKind(BudgetCategoryKind kind) {
    switch (kind) {
      case BudgetCategoryKind.salary:
        return Icons.savings_outlined;
      case BudgetCategoryKind.fuel:
        return Icons.local_gas_station_outlined;
      case BudgetCategoryKind.sports:
        return Icons.directions_run;
      case BudgetCategoryKind.travel:
        return Icons.directions_bus_outlined;
      case BudgetCategoryKind.clothes:
        return Icons.checkroom_outlined;
      case BudgetCategoryKind.eatingOut:
        return Icons.restaurant_outlined;
      case BudgetCategoryKind.entertainment:
        return Icons.music_note_outlined;
      case BudgetCategoryKind.general:
        return Icons.sell_outlined;
      case BudgetCategoryKind.gifts:
        return Icons.card_giftcard_outlined;
      case BudgetCategoryKind.holidays:
        return Icons.luggage_outlined;
      case BudgetCategoryKind.kids:
        return Icons.child_care_outlined;
      case BudgetCategoryKind.shopping:
        return Icons.shopping_cart_outlined;
      case BudgetCategoryKind.food:
        return Icons.shopping_basket_outlined;
      case BudgetCategoryKind.car:
        return Icons.directions_car_outlined;
      case BudgetCategoryKind.transport:
        return Icons.train_outlined;
      case BudgetCategoryKind.house:
        return Icons.home_outlined;
      case BudgetCategoryKind.health:
        return Icons.thermostat_outlined;
      case BudgetCategoryKind.communications:
        return Icons.phone_outlined;
      case BudgetCategoryKind.pets:
        return Icons.pets_outlined;
      case BudgetCategoryKind.taxi:
        return Icons.local_taxi_outlined;
      case BudgetCategoryKind.toiletry:
        return Icons.cleaning_services_outlined;
      case BudgetCategoryKind.bills:
        return Icons.receipt_long_outlined;
      case BudgetCategoryKind.custom:
        return Icons.label_outline;
    }
  }
}
