import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Chalkboard spendings manager palette — matches reference screenshots.
class BudgetColors {
  // Header / form (cream beige)
  static const headerBg = Color(0xFFF5F0E6);
  static const formBg = Color(0xFFF5F0E6);
  static const sectionHeader = Color(0xFFD4C9B8);
  static const rowLabelBg = Color(0xFFE8E0D4);
  static const brown = Color(0xFF4A3F3A);
  static const brownLight = Color(0xFF6B5E54);
  static const labelBlue = Color(0xFF3D6B9E);

  // Chalkboard
  static const chalkboard = Color(0xFF1A1A1A);
  static const chalkWhite = Color(0xFFF0F0F0);
  static const chalkIncome = Color(0xFFA8E6CF);
  static const chalkExpense = Color(0xFFFF8B94);
  static const chalkBalance = Color(0xFFA8D8EA);
  static const progressGreen = Color(0xFF5CB85C);
  static const progressRed = Color(0xFFE05D5D);

  // Transactions
  static const incomeSummaryBg = Color(0xFFD4EDDA);
  static const expenseSummaryBg = Color(0xFFF8D7DA);
  static const incomeText = Color(0xFF2D6A4F);
  static const expenseText = Color(0xFF8B2942);

  // Legacy aliases (home grid card)
  static const background = headerBg;
  static const primary = progressGreen;
  static const primaryDark = brown;
  static const primaryLight = Color(0xFFC8B9A8);
  static const income = incomeText;
  static const incomeBright = chalkIncome;
  static const expense = chalkExpense;
  static const expenseDark = expenseText;
  static const textPrimary = brown;
  static const textSecondary = brownLight;
  static const chartEmpty = Color(0xFFBDBDBD);
  static const cardBorder = Color(0xFFD4C9B8);

  static const categoryYellow = Color(0xFFF4C430);
  static const categoryBlue = Color(0xFF5B8DEF);
  static const categoryPurple = Color(0xFF9B72CF);
  static const categoryGreen = Color(0xFF52B788);
  static const categoryOrange = Color(0xFFE8925A);
  static const categoryPink = Color(0xFFE07A9A);
  static const categoryRed = Color(0xFFE05D5D);
  static const categoryTeal = Color(0xFF4ECDC4);
  static const categoryGrey = Color(0xFF9E9E9E);
}

class BudgetTextStyles {
  BudgetTextStyles._();

  static TextStyle chalk({double size = 18, Color color = BudgetColors.chalkWhite}) =>
      GoogleFonts.patrickHand(fontSize: size, color: color, height: 1.3);

  static TextStyle header({double size = 16, FontWeight weight = FontWeight.w600}) =>
      GoogleFonts.lato(fontSize: size, color: BudgetColors.brown, fontWeight: weight);

  static TextStyle tabLabel({bool active = false}) => GoogleFonts.lato(
        fontSize: 11,
        color: BudgetColors.brown,
        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
      );

  static TextStyle formLabel() =>
      GoogleFonts.lato(fontSize: 14, color: BudgetColors.labelBlue, fontWeight: FontWeight.w500);

  static TextStyle formValue({Color? color}) =>
      GoogleFonts.lato(fontSize: 14, color: color ?? BudgetColors.brown);

  static TextStyle transactionTitle() =>
      GoogleFonts.lora(fontSize: 16, color: BudgetColors.brown, fontWeight: FontWeight.w500);

  static TextStyle transactionDate() =>
      GoogleFonts.lato(fontSize: 12, color: BudgetColors.brownLight);
}
