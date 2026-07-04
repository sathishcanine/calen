import 'package:intl/intl.dart';

/// Currency formatting and amount input helpers for the budget module.
class BudgetFormat {
  BudgetFormat._();

  static final _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

  static String currency(double amount) => _currency.format(amount);

  /// Whole-number currency for home grid cards (no .00).
  static String currencyCompact(double amount) {
    final rounded = amount.round();
    return NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(rounded);
  }

  static String monthName(int month) {
    const names = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return names[month - 1];
  }

  static String fullDate(DateTime date) => DateFormat('EEEE, d MMMM').format(date);

  static String transactionDate(DateTime date) => DateFormat('EEEE, d MMM yyyy').format(date);

  static String shortDate(DateTime date) => DateFormat('dd MMM yyyy').format(date);

  static String percent(double value) {
    if (value >= 100) return '100%';
    if (value <= 0) return '0%';
    if (value >= 10) return '${value.round()}%';
    return '${value.toStringAsFixed(1)}%';
  }
}

/// Simple chained calculator for amount entry (left-to-right evaluation).
class BudgetAmountCalculator {
  String _display = '0';
  double? _leftOperand;
  String? _operator;
  bool _freshEntry = true;

  String get display => _display;

  double get resolvedAmount {
    final current = double.tryParse(_display) ?? 0;
    if (_operator != null && _leftOperand != null) {
      return _compute(_leftOperand!, current, _operator!);
    }
    return current;
  }

  bool get hasValidAmount => resolvedAmount > 0;

  void clear() {
    _display = '0';
    _leftOperand = null;
    _operator = null;
    _freshEntry = true;
  }

  void backspace() {
    if (_display.length <= 1 || (_display.length == 2 && _display.startsWith('-'))) {
      _display = '0';
      _freshEntry = true;
      return;
    }
    _display = _display.substring(0, _display.length - 1);
    if (_display.isEmpty || _display == '-') {
      _display = '0';
      _freshEntry = true;
    }
  }

  void input(String key) {
    if (key == '=') {
      _equals();
      return;
    }
    if (_isOperator(key)) {
      _applyOperator(key);
      return;
    }
    if (key == '.') {
      _inputDecimal();
      return;
    }
    _inputDigit(key);
  }

  void _inputDigit(String digit) {
    if (_freshEntry) {
      _display = digit;
      _freshEntry = false;
    } else if (_display == '0') {
      _display = digit;
    } else if (_display.length < 12) {
      _display += digit;
    }
  }

  void _inputDecimal() {
    if (_freshEntry) {
      _display = '0.';
      _freshEntry = false;
      return;
    }
    if (!_display.contains('.') && _display.length < 12) {
      _display += '.';
    }
  }

  void _applyOperator(String op) {
    final current = double.tryParse(_display) ?? 0;
    if (_leftOperand != null && _operator != null && !_freshEntry) {
      final result = _compute(_leftOperand!, current, _operator!);
      _leftOperand = result;
      _display = _trimResult(result);
    } else {
      _leftOperand = current;
    }
    _operator = op;
    _freshEntry = true;
  }

  void _equals() {
    if (_leftOperand == null || _operator == null) return;
    final current = double.tryParse(_display) ?? 0;
    final result = _compute(_leftOperand!, current, _operator!);
    _display = _trimResult(result);
    _leftOperand = null;
    _operator = null;
    _freshEntry = true;
  }

  double _compute(double left, double right, String op) {
    switch (op) {
      case '+':
        return left + right;
      case '-':
        return left - right;
      case '×':
        return left * right;
      case '÷':
        if (right == 0) return left;
        return left / right;
      default:
        return right;
    }
  }

  bool _isOperator(String key) => key == '+' || key == '-' || key == '×' || key == '÷';

  String _trimResult(double value) {
    if (value.isNaN || value.isInfinite) return '0';
    final rounded = double.parse(value.toStringAsFixed(2));
    if (rounded == rounded.roundToDouble()) {
      return rounded.toInt().toString();
    }
    return rounded.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
  }
}
