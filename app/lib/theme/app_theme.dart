import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const maroon = Color(0xFF7B1A2D);
  static const maroonDark = Color(0xFF4A0E1C);
  static const maroonLight = Color(0xFF9E2A42);
  static const gold = Color(0xFFD4A853);
  static const goldLight = Color(0xFFF5D78E);
  static const goldDark = Color(0xFFB8860B);
  static const cream = Color(0xFFFFF9F2);
  static const creamDark = Color(0xFFF5EBE0);
  static const surface = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF2C1810);
  static const textSecondary = Color(0xFF6B5344);
  static const greenBanner = Color(0xFF1B6B3A);
  static const greenBannerLight = Color(0xFF27AE60);
  static const dailyRed = Color(0xFFC0392B);
  static const dailyRedLight = Color(0xFFE74C3C);
  static const monthlyGreen = Color(0xFF1B6B3A);
  static const monthlyGreenLight = Color(0xFF27AE60);
  static const labelPink = Color(0xFFAD1457);
  static const auspicious = Color(0xFF2D6A4F);
  static const inauspicious = Color(0xFF8B2500);
  static const sundayRed = Color(0xFFD32F2F);

  // Premium panchangam palette — "நாள் காட்டி" detail screen.
  static const crimson = Color(0xFF9D174D);
  static const crimsonDark = Color(0xFF741238);
  static const crimsonSoft = Color(0xFFFCE7F0);
  static const emerald = Color(0xFF15803D);
  static const emeraldDark = Color(0xFF0F5C2C);
  static const emeraldSoft = Color(0xFFE3F5E9);
  static const numberRed = Color(0xFFDC2626);
  static const softCream = Color(0xFFFFFDF6);
  static const borderGrey = Color(0xFFE7E1D8);
}

class AppDecorations {
  static const cardRadius = 16.0;
  static const cardRadiusSm = 12.0;

  static BoxDecoration card({Color? color}) => BoxDecoration(
        color: color ?? AppColors.surface,
        borderRadius: BorderRadius.circular(cardRadius),
        boxShadow: [
          BoxShadow(
            color: AppColors.maroon.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      );

  static BoxDecoration goldBorder() => BoxDecoration(
        borderRadius: BorderRadius.circular(cardRadius),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.5), width: 1.5),
        gradient: LinearGradient(
          colors: [
            AppColors.goldLight.withValues(alpha: 0.15),
            AppColors.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );

  static const headerGradient = LinearGradient(
    colors: [AppColors.maroonDark, AppColors.maroon, AppColors.maroonLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const crimsonGradient = LinearGradient(
    colors: [AppColors.crimsonDark, AppColors.crimson],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const emeraldGradient = LinearGradient(
    colors: [AppColors.emeraldDark, AppColors.emerald],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static BoxDecoration softCard({Color? color}) => BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(cardRadiusSm),
        border: Border.all(color: AppColors.borderGrey),
      );

  static const heroGradient = LinearGradient(
    colors: [AppColors.maroonDark, AppColors.maroon, AppColors.maroonLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const spiritualGradient = LinearGradient(
    colors: [Color(0xFF1A1040), Color(0xFF2C1F5C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const tealGradient = LinearGradient(
    colors: [Color(0xFF1A6B6B), Color(0xFF2D9B9B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const forestGradient = LinearGradient(
    colors: [Color(0xFF1B5E3A), Color(0xFF2E8B57)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static BoxDecoration glassCard({Color? tint}) => BoxDecoration(
        color: (tint ?? Colors.white).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(cardRadius),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: AppColors.maroon.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      );

  static BoxDecoration iconTile(LinearGradient gradient) => BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(cardRadiusSm),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      );
}

ThemeData buildAppTheme() {
  final tamil = GoogleFonts.notoSansTamilTextTheme();
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.cream,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.maroon,
      primary: AppColors.maroon,
      secondary: AppColors.gold,
      surface: AppColors.surface,
    ),
    textTheme: tamil.apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.cream,
      foregroundColor: AppColors.maroon,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: tamil.titleLarge?.copyWith(
        color: AppColors.maroon,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.3,
      ),
      iconTheme: const IconThemeData(color: AppColors.maroon),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDecorations.cardRadius)),
      margin: EdgeInsets.zero,
    ),
    dividerTheme: DividerThemeData(
      color: AppColors.creamDark,
      thickness: 1,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.maroon,
    ),
  );
  return base;
}
