import 'package:flutter/material.dart';

import '../services/calendar_repository.dart';
import '../theme/app_theme.dart';
import 'raasi_palan_detail_screen.dart';

enum RaasiPalanType { today, weekly, monthly, yearly }

extension RaasiPalanTypeApi on RaasiPalanType {
  String get apiPeriod {
    switch (this) {
      case RaasiPalanType.today:
        return 'today';
      case RaasiPalanType.weekly:
        return 'weekly';
      case RaasiPalanType.monthly:
        return 'monthly';
      case RaasiPalanType.yearly:
        return 'yearly';
    }
  }
}

// ─────────────────────────────────────────
// Data model for each of the 12 Raasis
// ─────────────────────────────────────────
class RaasiData {
  const RaasiData({
    required this.index,
    required this.nameTa,
    required this.nameEn,
    required this.assetPath,
    required this.rulingPlanetTa,
    required this.elementTa,
  });

  final int index;
  final String nameTa;
  final String nameEn;
  final String assetPath;
  final String rulingPlanetTa;
  final String elementTa;

  static const List<RaasiData> all = [
    RaasiData(
      index: 0,
      nameTa: 'மேஷம்',
      nameEn: 'Aries',
      assetPath: 'assets/images/zodiac/mesham.png',
      rulingPlanetTa: 'செவ்வாய்',
      elementTa: 'நெருப்பு',
    ),
    RaasiData(
      index: 1,
      nameTa: 'ரிஷபம்',
      nameEn: 'Taurus',
      assetPath: 'assets/images/zodiac/rishabam.png',
      rulingPlanetTa: 'சுக்ரன்',
      elementTa: 'பூமி',
    ),
    RaasiData(
      index: 2,
      nameTa: 'மிதுனம்',
      nameEn: 'Gemini',
      assetPath: 'assets/images/zodiac/midhunam.png',
      rulingPlanetTa: 'புதன்',
      elementTa: 'காற்று',
    ),
    RaasiData(
      index: 3,
      nameTa: 'கடகம்',
      nameEn: 'Cancer',
      assetPath: 'assets/images/zodiac/kadagam.png',
      rulingPlanetTa: 'சந்திரன்',
      elementTa: 'நீர்',
    ),
    RaasiData(
      index: 4,
      nameTa: 'சிம்மம்',
      nameEn: 'Leo',
      assetPath: 'assets/images/zodiac/simmam.png',
      rulingPlanetTa: 'சூரியன்',
      elementTa: 'நெருப்பு',
    ),
    RaasiData(
      index: 5,
      nameTa: 'கன்னி',
      nameEn: 'Virgo',
      assetPath: 'assets/images/zodiac/kanni.png',
      rulingPlanetTa: 'புதன்',
      elementTa: 'பூமி',
    ),
    RaasiData(
      index: 6,
      nameTa: 'துலாம்',
      nameEn: 'Libra',
      assetPath: 'assets/images/zodiac/thulaam.png',
      rulingPlanetTa: 'சுக்ரன்',
      elementTa: 'காற்று',
    ),
    RaasiData(
      index: 7,
      nameTa: 'விருச்சிகம்',
      nameEn: 'Scorpio',
      assetPath: 'assets/images/zodiac/viruchigam.png',
      rulingPlanetTa: 'செவ்வாய்',
      elementTa: 'நீர்',
    ),
    RaasiData(
      index: 8,
      nameTa: 'தனுசு',
      nameEn: 'Sagittarius',
      assetPath: 'assets/images/zodiac/dhanusu.png',
      rulingPlanetTa: 'குரு',
      elementTa: 'நெருப்பு',
    ),
    RaasiData(
      index: 9,
      nameTa: 'மகரம்',
      nameEn: 'Capricorn',
      assetPath: 'assets/images/zodiac/magaram.png',
      rulingPlanetTa: 'சனி',
      elementTa: 'பூமி',
    ),
    RaasiData(
      index: 10,
      nameTa: 'கும்பம்',
      nameEn: 'Aquarius',
      assetPath: 'assets/images/zodiac/kumbam.png',
      rulingPlanetTa: 'சனி',
      elementTa: 'காற்று',
    ),
    RaasiData(
      index: 11,
      nameTa: 'மீனம்',
      nameEn: 'Pisces',
      assetPath: 'assets/images/zodiac/meenam.png',
      rulingPlanetTa: 'குரு',
      elementTa: 'நீர்',
    ),
  ];
}

// ─────────────────────────────────────────
// Screen: 12 zodiac sign grid
// ─────────────────────────────────────────
class RaasiSignSelectorScreen extends StatelessWidget {
  const RaasiSignSelectorScreen({
    super.key,
    required this.type,
    required this.title,
    required this.repository,
  });

  final RaasiPalanType type;
  final String title;
  final CalendarRepository repository;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: Text(title)),
      body: Column(
        children: [
          // Subtitle strip
          Container(
            width: double.infinity,
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            child: Text(
              'உங்கள் ராசியை தேர்வு செய்யுங்கள்',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.82,
              ),
              itemCount: RaasiData.all.length,
              itemBuilder: (context, index) {
                final raasi = RaasiData.all[index];
                return _RaasiSignCard(
                  raasi: raasi,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RaasiPalanDetailScreen(
                          raasi: raasi,
                          type: type,
                          typeTitle: title,
                          repository: repository,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// Individual zodiac sign card
// ─────────────────────────────────────────
class _RaasiSignCard extends StatelessWidget {
  const _RaasiSignCard({required this.raasi, required this.onTap});

  final RaasiData raasi;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFE8C87A).withValues(alpha: 0.65),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.maroon.withValues(alpha: 0.07),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Classical illustrative raasi artwork (ram/bull/etc.)
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: ColoredBox(
                  color: const Color(0xFFFFF3C4),
                  child: Image.asset(
                    raasi.assetPath,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              raasi.nameTa,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 1),
            Text(
              raasi.nameEn,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFFB5451B).withValues(alpha: 0.75),
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
