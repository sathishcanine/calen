import 'package:flutter/material.dart';

/// Full illustrative zodiac (ராசி) artwork — one dedicated PNG per sign.
///
/// Assets live under `assets/images/zodiac/` (mesham, rishabam, … meenam).
class ZodiacSignIcon extends StatelessWidget {
  const ZodiacSignIcon({
    super.key,
    required this.index, // 0 = மேஷம் … 11 = மீனம்
    this.size = 56,
    this.borderRadius = 10,
    this.showGoldenBg = true,
  });

  final int index;
  final double size;
  final double borderRadius;
  final bool showGoldenBg;

  static const assetPaths = [
    'assets/images/zodiac/mesham.png',
    'assets/images/zodiac/rishabam.png',
    'assets/images/zodiac/midhunam.png',
    'assets/images/zodiac/kadagam.png',
    'assets/images/zodiac/simmam.png',
    'assets/images/zodiac/kanni.png',
    'assets/images/zodiac/thulaam.png',
    'assets/images/zodiac/viruchigam.png',
    'assets/images/zodiac/dhanusu.png',
    'assets/images/zodiac/magaram.png',
    'assets/images/zodiac/kumbam.png',
    'assets/images/zodiac/meenam.png',
  ];

  String get assetPath => assetPaths[index.clamp(0, 11)];

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      assetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    );

    if (!showGoldenBg) return image;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFF8E1), Color(0xFFFFECB3)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        padding: EdgeInsets.all(size * 0.08),
        child: image,
      ),
    );
  }
}
