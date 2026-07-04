import '../models/budget.dart';
import '../theme/budget_theme.dart';

/// Default categories matching the reference spendings manager app.
class BudgetDefaults {
  BudgetDefaults._();

  static List<BudgetCategory> allCategories() => [
        const BudgetCategory(
          id: 'salary',
          name: 'Salary',
          kind: BudgetCategoryKind.salary,
          color: BudgetColors.incomeText,
          isIncome: true,
          sortOrder: 0,
        ),
        const BudgetCategory(
          id: 'fuel',
          name: 'Fuel',
          kind: BudgetCategoryKind.fuel,
          color: BudgetColors.brown,
          isIncome: false,
          sortOrder: 1,
        ),
        const BudgetCategory(
          id: 'sports',
          name: 'Sports',
          kind: BudgetCategoryKind.sports,
          color: BudgetColors.brown,
          isIncome: false,
          sortOrder: 2,
        ),
        const BudgetCategory(
          id: 'travel',
          name: 'Travel',
          kind: BudgetCategoryKind.travel,
          color: BudgetColors.brown,
          isIncome: false,
          sortOrder: 3,
        ),
        const BudgetCategory(
          id: 'clothes',
          name: 'Clothes',
          kind: BudgetCategoryKind.clothes,
          color: BudgetColors.brown,
          isIncome: false,
          sortOrder: 4,
        ),
        const BudgetCategory(
          id: 'eating_out',
          name: 'Eating Out',
          kind: BudgetCategoryKind.eatingOut,
          color: BudgetColors.brown,
          isIncome: false,
          sortOrder: 5,
        ),
        const BudgetCategory(
          id: 'entertainment',
          name: 'Entertainment',
          kind: BudgetCategoryKind.entertainment,
          color: BudgetColors.brown,
          isIncome: false,
          sortOrder: 6,
        ),
        const BudgetCategory(
          id: 'general',
          name: 'General',
          kind: BudgetCategoryKind.general,
          color: BudgetColors.brown,
          isIncome: false,
          sortOrder: 7,
        ),
        const BudgetCategory(
          id: 'gifts',
          name: 'Gifts',
          kind: BudgetCategoryKind.gifts,
          color: BudgetColors.brown,
          isIncome: false,
          sortOrder: 8,
        ),
        const BudgetCategory(
          id: 'holidays',
          name: 'Holidays',
          kind: BudgetCategoryKind.holidays,
          color: BudgetColors.brown,
          isIncome: false,
          sortOrder: 9,
        ),
        const BudgetCategory(
          id: 'kids',
          name: 'Kids',
          kind: BudgetCategoryKind.kids,
          color: BudgetColors.brown,
          isIncome: false,
          sortOrder: 10,
        ),
        const BudgetCategory(
          id: 'shopping',
          name: 'Shopping',
          kind: BudgetCategoryKind.shopping,
          color: BudgetColors.brown,
          isIncome: false,
          sortOrder: 11,
        ),
      ];

  static List<BudgetCategory> expenseCategories() =>
      allCategories().where((c) => !c.isIncome).toList();
}
