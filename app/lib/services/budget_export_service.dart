import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/budget.dart';
import '../utils/app_share.dart';
import '../utils/budget_format.dart';

/// Export monthly budget data as a shareable CSV file.
class BudgetExportService {
  BudgetExportService._();

  static final BudgetExportService instance = BudgetExportService._();

  Future<void> exportMonth({
    required int year,
    required int month,
    required BudgetMonthSummary summary,
    required Map<String, BudgetCategory> categoryMap,
  }) async {
    final csv = _buildCsv(year, month, summary, categoryMap);
    final dir = await getTemporaryDirectory();
    final monthLabel = BudgetFormat.monthName(month).toLowerCase();
    final file = File('${dir.path}/budget_${monthLabel}_$year.csv');
    await file.writeAsString(csv);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: AppShare.withInstallFooter(
          '${BudgetFormat.monthName(month)} $year செலவு அறிக்கை',
        ),
        subject: 'Budget ${BudgetFormat.monthName(month)} $year',
      ),
    );
  }

  String _buildCsv(
    int year,
    int month,
    BudgetMonthSummary summary,
    Map<String, BudgetCategory> categoryMap,
  ) {
    final buffer = StringBuffer();
    final monthName = BudgetFormat.monthName(month);

    buffer.writeln('Month,$monthName,$year');
    buffer.writeln('Income,${_amount(summary.totalIncome)}');
    buffer.writeln('Expense,${_amount(summary.totalExpense)}');
    buffer.writeln('Balance,${_amount(summary.balance)}');
    buffer.writeln();
    buffer.writeln('Date,Type,Category,Amount,Note');

    final transactions = [...summary.allTransactions]
      ..sort((a, b) => b.date.compareTo(a.date));

    for (final tx in transactions) {
      final category = categoryMap[tx.categoryId]?.name ?? 'Unknown';
      final type = tx.type == BudgetTransactionType.income ? 'Income' : 'Expense';
      final date = BudgetFormat.shortDate(tx.date);
      buffer.writeln(
        '${_escape(date)},$type,${_escape(category)},${_amount(tx.amount)},${_escape(tx.note ?? '')}',
      );
    }

    return buffer.toString();
  }

  String _amount(double value) => value.round().toString();

  String _escape(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}
