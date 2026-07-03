import 'package:flutter/material.dart';

import '../services/calendar_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/menu_icons.dart';
import '../widgets/native_ad_widget.dart';
import 'chandrashtamam_screen.dart';
import 'marriage_porutham_screen.dart';
import 'nazhigai_converter_screen.dart';
import 'numerology_screen.dart';
import 'tarabalam_screen.dart';

class _SearchTool {
  const _SearchTool({
    required this.label,
    required this.subtitle,
    required this.iconKind,
    required this.gradient,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final MenuIconKind iconKind;
  final LinearGradient gradient;
  final VoidCallback onTap;
}

/// ஜோதிட தேடல் — quick access to jyotish calculators.
class JyotishaSearchScreen extends StatelessWidget {
  const JyotishaSearchScreen({
    super.key,
    required this.repository,
    required this.initialDate,
  });

  final CalendarRepository repository;
  final DateTime initialDate;

  @override
  Widget build(BuildContext context) {
    final tools = [
      _SearchTool(
        label: 'திருமண பொருத்தம்',
        subtitle: '10 பொருத்தம் கணக்கீடு',
        iconKind: MenuIconKind.marriage,
        gradient: AppDecorations.forestGradient,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => MarriagePoruthamScreen(repository: repository)),
        ),
      ),
      _SearchTool(
        label: 'எண்கணிதம்',
        subtitle: 'பெயர் · தேதி எண்',
        iconKind: MenuIconKind.numerology,
        gradient: const LinearGradient(
          colors: [Color(0xFF8B1A1A), Color(0xFFC62828)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => NumerologyScreen(repository: repository)),
        ),
      ),
      _SearchTool(
        label: 'நாழிகை converter',
        subtitle: 'நேரம் மாற்றம்',
        iconKind: MenuIconKind.nazhigai,
        gradient: const LinearGradient(
          colors: [Color(0xFFE65100), Color(0xFFF9A825)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => NazhigaiConverterScreen(repository: repository, initialDate: initialDate),
          ),
        ),
      ),
      _SearchTool(
        label: 'சந்திராஷ்டமம்',
        subtitle: 'நட்சத்திர தோஷம்',
        iconKind: MenuIconKind.chandrashtamam,
        gradient: const LinearGradient(
          colors: [Color(0xFF0D3B66), Color(0xFF1565C0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChandrashtamamScreen(repository: repository, initialDate: initialDate),
          ),
        ),
      ),
      _SearchTool(
        label: 'தாரா பலன்',
        subtitle: 'நட்சத்திர தாரா காலம்',
        iconKind: MenuIconKind.tara,
        gradient: const LinearGradient(
          colors: [Color(0xFF6A1B9A), Color(0xFF9C27B0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TarabalamScreen(repository: repository, initialDate: initialDate),
          ),
        ),
      ),
    ];

    return Scaffold(
      bottomNavigationBar: const NativeAdWidget(),
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        title: const Text('ஜோதிட தேடல்', style: TextStyle(fontSize: 16)),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: tools.length,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final tool = tools[index];
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: tool.onTap,
              borderRadius: BorderRadius.circular(16),
              child: Ink(
                decoration: AppDecorations.glassCard(),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: AppDecorations.iconTile(tool.gradient),
                        child: Center(child: MenuIcon(kind: tool.iconKind, size: 26)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tool.label,
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            Text(
                              tool.subtitle,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, color: AppColors.maroon.withValues(alpha: 0.5)),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
