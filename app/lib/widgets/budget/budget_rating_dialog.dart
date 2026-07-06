import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';
import '../../theme/budget_theme.dart';

enum BudgetRatingChoice { yes, maybe }

/// Rating prompt shown when leaving the monthly budget hub.
Future<BudgetRatingChoice?> showBudgetRatingDialog(BuildContext context) {
  return showDialog<BudgetRatingChoice>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => const _BudgetRatingDialog(),
  );
}

class _BudgetRatingDialog extends StatelessWidget {
  const _BudgetRatingDialog();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.gold.withValues(alpha: 0.45)),
            boxShadow: [
              BoxShadow(
                color: AppColors.maroon.withValues(alpha: 0.2),
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
                  decoration: const BoxDecoration(gradient: AppDecorations.headerGradient),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.gold.withValues(alpha: 0.6)),
                        ),
                        child: const Icon(Icons.star_rounded, color: AppColors.goldLight, size: 40),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'பயன்பாட்டை விரும்புகிறீர்களா?',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Enjoying the app?',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
                  child: Column(
                    children: [
                      Text(
                        'உங்கள் விமர்சனம் எங்களுக்கு மிகவும் உதவியாக இருக்கும். Play Store-ல் நமக்கு மதிப்பீடு கொடுக்குங்கள்!',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.lato(
                          fontSize: 14,
                          color: BudgetColors.brown,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (i) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: Icon(
                              Icons.star_rounded,
                              color: AppColors.gold,
                              size: i < 4 ? 30 : 26,
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () => Navigator.pop(context, BudgetRatingChoice.yes),
                          icon: const Icon(Icons.thumb_up_alt_rounded, size: 20),
                          label: const Text('ஆம், மதிப்பிடுங்கள்'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.maroon,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context, BudgetRatingChoice.maybe),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: BudgetColors.brown,
                            side: BorderSide(color: BudgetColors.brown.withValues(alpha: 0.35)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text('பிறகு பார்க்கலாம்'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
