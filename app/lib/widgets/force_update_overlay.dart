import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/app_update_config.dart';
import '../theme/app_theme.dart';
import 'kolam_pattern.dart';

/// Full-screen, non-dismissible update prompt driven by Firebase Remote Config.
class ForceUpdateOverlay extends StatelessWidget {
  const ForceUpdateOverlay({super.key, required this.config});

  final AppUpdateConfig config;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Material(
        color: AppColors.cream,
        child: KolamPattern(
          opacity: 0.08,
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: _UpdateCard(config: config),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _UpdateCard extends StatelessWidget {
  const _UpdateCard({required this.config});

  final AppUpdateConfig config;

  Future<void> _openStore() async {
    final uri = Uri.parse(config.storeUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(
            color: AppColors.maroon.withValues(alpha: 0.18),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
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
                  child: const Icon(
                    Icons.system_update_alt_rounded,
                    color: AppColors.goldLight,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  config.title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'பயன்பாட்டைத் தொடர புதுப்பிப்பு அவசியம்',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.88),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (config.whatsNewItems.isNotEmpty) ...[
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome_rounded,
                          color: AppColors.goldDark, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        "What's New / புதியவை",
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: AppColors.maroon,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ...List.generate(config.whatsNewItems.length, (index) {
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index == config.whatsNewItems.length - 1 ? 0 : 12,
                      ),
                      child: _WhatsNewRow(
                        index: index + 1,
                        text: config.whatsNewItems[index],
                      ),
                    );
                  }),
                  const SizedBox(height: 22),
                ],
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.maroonDark, AppColors.maroon, AppColors.maroonLight],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.maroon.withValues(alpha: 0.28),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _openStore,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        config.buttonText,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WhatsNewRow extends StatelessWidget {
  const _WhatsNewRow({required this.index, required this.text});

  final int index;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.goldLight.withValues(alpha: 0.9),
                AppColors.gold,
              ],
            ),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.goldDark.withValues(alpha: 0.35)),
          ),
          child: Text(
            '$index',
            style: const TextStyle(
              color: AppColors.maroonDark,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                    height: 1.45,
                  ),
            ),
          ),
        ),
      ],
    );
  }
}
