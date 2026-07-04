import 'package:flutter/material.dart';

enum BudgetTransactionType { income, expense }

enum BudgetCategoryKind {
  salary,
  fuel,
  sports,
  travel,
  clothes,
  eatingOut,
  entertainment,
  general,
  gifts,
  holidays,
  kids,
  shopping,
  bills,
  car,
  communications,
  food,
  health,
  house,
  pets,
  taxi,
  toiletry,
  transport,
  custom,
}

class BudgetCategory {
  const BudgetCategory({
    required this.id,
    required this.name,
    required this.kind,
    required this.color,
    required this.isIncome,
    this.isCustom = false,
    this.sortOrder = 0,
  });

  final String id;
  final String name;
  final BudgetCategoryKind kind;
  final Color color;
  final bool isIncome;
  final bool isCustom;
  final int sortOrder;

  BudgetCategory copyWith({
    String? name,
    Color? color,
  }) {
    return BudgetCategory(
      id: id,
      name: name ?? this.name,
      kind: kind,
      color: color ?? this.color,
      isIncome: isIncome,
      isCustom: isCustom,
      sortOrder: sortOrder,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'kind': kind.name,
        'color_value': color.toARGB32(),
        'is_income': isIncome ? 1 : 0,
        'is_custom': isCustom ? 1 : 0,
        'sort_order': sortOrder,
      };

  factory BudgetCategory.fromMap(Map<String, Object?> map) {
    final kindName = map['kind'] as String? ?? BudgetCategoryKind.custom.name;
    return BudgetCategory(
      id: map['id'] as String,
      name: map['name'] as String,
      kind: BudgetCategoryKind.values.firstWhere(
        (k) => k.name == kindName,
        orElse: () => BudgetCategoryKind.custom,
      ),
      color: Color(map['color_value'] as int),
      isIncome: (map['is_income'] as int? ?? 0) == 1,
      isCustom: (map['is_custom'] as int? ?? 0) == 1,
      sortOrder: map['sort_order'] as int? ?? 0,
    );
  }
}

class BudgetTransaction {
  const BudgetTransaction({
    required this.id,
    required this.categoryId,
    required this.type,
    required this.amount,
    required this.date,
    required this.createdAt,
    this.note,
  });

  final String id;
  final String categoryId;
  final BudgetTransactionType type;
  final double amount;
  final String? note;
  final DateTime date;
  final DateTime createdAt;

  Map<String, Object?> toMap() => {
        'id': id,
        'category_id': categoryId,
        'type': type.name,
        'amount': amount,
        'note': note,
        'date': _dateKey(date),
        'created_at': createdAt.toIso8601String(),
      };

  factory BudgetTransaction.fromMap(Map<String, Object?> map) {
    return BudgetTransaction(
      id: map['id'] as String,
      categoryId: map['category_id'] as String,
      type: BudgetTransactionType.values.firstWhere(
        (t) => t.name == map['type'],
        orElse: () => BudgetTransactionType.expense,
      ),
      amount: (map['amount'] as num).toDouble(),
      note: map['note'] as String?,
      date: DateTime.parse(map['date'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

class BudgetCategorySummary {
  const BudgetCategorySummary({
    required this.category,
    required this.total,
    required this.transactions,
    required this.percentOfExpenses,
  });

  final BudgetCategory category;
  final double total;
  final List<BudgetTransaction> transactions;
  final double percentOfExpenses;
}

class BudgetMonthSummary {
  const BudgetMonthSummary({
    required this.year,
    required this.month,
    required this.totalIncome,
    required this.totalExpense,
    required this.balance,
    required this.expenseByCategory,
    required this.incomeByCategory,
    required this.allTransactions,
  });

  final int year;
  final int month;
  final double totalIncome;
  final double totalExpense;
  final double balance;
  final List<BudgetCategorySummary> expenseByCategory;
  final List<BudgetCategorySummary> incomeByCategory;
  final List<BudgetTransaction> allTransactions;

  bool get hasData => totalIncome > 0 || totalExpense > 0;
  bool get isNegativeBalance => balance < 0;
}

String _dateKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
