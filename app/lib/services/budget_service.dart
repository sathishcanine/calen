import '../models/budget.dart';
import '../theme/budget_theme.dart';
import 'budget_database.dart';

class BudgetService {
  BudgetService._();

  static final BudgetService instance = BudgetService._();

  int _idCounter = 0;

  Future<void> ensureInitialized() => BudgetDatabase.instance.ensureInitialized();

  String _newId(String prefix) {
    _idCounter++;
    return '$prefix-${DateTime.now().millisecondsSinceEpoch}-$_idCounter';
  }

  Future<List<BudgetCategory>> getExpenseCategories() =>
      BudgetDatabase.instance.getCategories(isIncome: false);

  Future<List<BudgetCategory>> getIncomeCategories() =>
      BudgetDatabase.instance.getCategories(isIncome: true);

  Future<List<BudgetCategory>> getAllCategories() =>
      BudgetDatabase.instance.getCategories();

  Future<BudgetCategory?> getCategory(String id) =>
      BudgetDatabase.instance.getCategoryById(id);

  Future<BudgetMonthSummary> getMonthSummary(int year, int month) async {
    final transactions = await BudgetDatabase.instance.getTransactionsForMonth(year, month);
    final categories = await BudgetDatabase.instance.getCategories();
    return _summarize(year, month, transactions, categories);
  }

  Future<List<BudgetMonthSummary>> getYearSummaries(int year) async {
    final transactions = await BudgetDatabase.instance.getTransactionsForYear(year);
    final categories = await BudgetDatabase.instance.getCategories();
    return List.generate(
      12,
      (i) => _summarize(year, i + 1, transactions, categories),
    );
  }

  BudgetMonthSummary _summarize(
    int year,
    int month,
    List<BudgetTransaction> sourceTransactions,
    List<BudgetCategory> categories,
  ) {
    final transactions = sourceTransactions.where((tx) {
      return tx.date.year == year && tx.date.month == month;
    }).toList();

    final categoryMap = {for (final c in categories) c.id: c};

    var totalIncome = 0.0;
    var totalExpense = 0.0;

    final incomeGroups = <String, List<BudgetTransaction>>{};
    final expenseGroups = <String, List<BudgetTransaction>>{};

    for (final tx in transactions) {
      if (tx.type == BudgetTransactionType.income) {
        totalIncome += tx.amount;
        incomeGroups.putIfAbsent(tx.categoryId, () => []).add(tx);
      } else {
        totalExpense += tx.amount;
        expenseGroups.putIfAbsent(tx.categoryId, () => []).add(tx);
      }
    }

    List<BudgetCategorySummary> buildSummaries(
      Map<String, List<BudgetTransaction>> groups,
      double expenseTotal,
    ) {
      final summaries = <BudgetCategorySummary>[];
      for (final entry in groups.entries) {
        final category = categoryMap[entry.key];
        if (category == null) continue;
        final total = entry.value.fold<double>(0, (sum, t) => sum + t.amount);
        final percent = expenseTotal > 0 ? (total / expenseTotal) * 100 : 0.0;
        summaries.add(
          BudgetCategorySummary(
            category: category,
            total: total,
            transactions: entry.value,
            percentOfExpenses: percent,
          ),
        );
      }
      summaries.sort((a, b) => b.total.compareTo(a.total));
      return summaries;
    }

    return BudgetMonthSummary(
      year: year,
      month: month,
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      balance: totalIncome - totalExpense,
      expenseByCategory: buildSummaries(expenseGroups, totalExpense),
      incomeByCategory: buildSummaries(incomeGroups, totalExpense),
      allTransactions: transactions,
    );
  }

  Future<BudgetTransaction> addTransaction({
    required BudgetTransactionType type,
    required String categoryId,
    required double amount,
    required DateTime date,
    String? note,
  }) async {
    if (amount <= 0) {
      throw ArgumentError('Amount must be greater than zero');
    }

    final transaction = BudgetTransaction(
      id: _newId('tx'),
      categoryId: categoryId,
      type: type,
      amount: amount,
      note: note?.trim().isEmpty == true ? null : note?.trim(),
      date: DateTime(date.year, date.month, date.day),
      createdAt: DateTime.now(),
    );

    await BudgetDatabase.instance.insertTransaction(transaction);
    return transaction;
  }

  Future<void> deleteTransaction(String id) =>
      BudgetDatabase.instance.deleteTransaction(id);

  Future<BudgetCategory> addCustomCategory({
    required String name,
    required bool isIncome,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Category name cannot be empty');
    }

    final categories = await BudgetDatabase.instance.getCategories(isIncome: isIncome);
    final category = BudgetCategory(
      id: _newId('cat'),
      name: trimmed,
      kind: BudgetCategoryKind.custom,
      color: isIncome ? BudgetColors.incomeBright : BudgetColors.categoryGrey,
      isIncome: isIncome,
      isCustom: true,
      sortOrder: categories.length,
    );

    await BudgetDatabase.instance.insertCategory(category);
    return category;
  }
}
