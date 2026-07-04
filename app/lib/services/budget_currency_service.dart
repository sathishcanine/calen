import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/budget_currency.dart';

/// Persists and broadcasts the selected budget display currency.
class BudgetCurrencyService {
  BudgetCurrencyService._();

  static final BudgetCurrencyService instance = BudgetCurrencyService._();

  static const _prefKey = 'budget_currency_id';

  final ValueNotifier<BudgetCurrencyOption> selected =
      ValueNotifier<BudgetCurrencyOption>(BudgetCurrencies.inr);

  bool _initialized = false;

  Future<void> ensureInitialized() async {
    if (_initialized) return;
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_prefKey);
    if (id != null) {
      selected.value = BudgetCurrencies.byId(id);
    }
    _initialized = true;
  }

  Future<void> setCurrency(BudgetCurrencyOption option) async {
    selected.value = option;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, option.id);
  }
}
