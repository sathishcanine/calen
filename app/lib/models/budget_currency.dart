/// Display currency option for the budget module.
class BudgetCurrencyOption {
  const BudgetCurrencyOption({
    required this.id,
    required this.label,
    required this.symbol,
    required this.code,
    required this.locale,
  });

  final String id;
  final String label;
  final String symbol;
  final String code;
  final String locale;
}

class BudgetCurrencies {
  BudgetCurrencies._();

  static const inr = BudgetCurrencyOption(
    id: 'inr',
    label: 'India — Rupee',
    symbol: '₹',
    code: 'INR',
    locale: 'en_IN',
  );

  static const usd = BudgetCurrencyOption(
    id: 'usd',
    label: 'USA — Dollar',
    symbol: '\$',
    code: 'USD',
    locale: 'en_US',
  );

  static const eur = BudgetCurrencyOption(
    id: 'eur',
    label: 'Europe — Euro',
    symbol: '€',
    code: 'EUR',
    locale: 'de_DE',
  );

  static const gbp = BudgetCurrencyOption(
    id: 'gbp',
    label: 'UK — Pound',
    symbol: '£',
    code: 'GBP',
    locale: 'en_GB',
  );

  static const sgd = BudgetCurrencyOption(
    id: 'sgd',
    label: 'Singapore — Dollar',
    symbol: 'S\$',
    code: 'SGD',
    locale: 'en_SG',
  );

  static const myr = BudgetCurrencyOption(
    id: 'myr',
    label: 'Malaysia — Ringgit',
    symbol: 'RM',
    code: 'MYR',
    locale: 'ms_MY',
  );

  static const aed = BudgetCurrencyOption(
    id: 'aed',
    label: 'UAE — Dirham',
    symbol: 'AED',
    code: 'AED',
    locale: 'en_AE',
  );

  static const lkr = BudgetCurrencyOption(
    id: 'lkr',
    label: 'Sri Lanka — Rupee',
    symbol: 'Rs',
    code: 'LKR',
    locale: 'en_LK',
  );

  static const cad = BudgetCurrencyOption(
    id: 'cad',
    label: 'Canada — Dollar',
    symbol: 'C\$',
    code: 'CAD',
    locale: 'en_CA',
  );

  static const aud = BudgetCurrencyOption(
    id: 'aud',
    label: 'Australia — Dollar',
    symbol: 'A\$',
    code: 'AUD',
    locale: 'en_AU',
  );

  static const jpy = BudgetCurrencyOption(
    id: 'jpy',
    label: 'Japan — Yen',
    symbol: '¥',
    code: 'JPY',
    locale: 'ja_JP',
  );

  static const all = [inr, usd, eur, gbp, sgd, myr, aed, lkr, cad, aud, jpy];

  static BudgetCurrencyOption byId(String id) {
    return all.firstWhere((c) => c.id == id, orElse: () => inr);
  }
}
