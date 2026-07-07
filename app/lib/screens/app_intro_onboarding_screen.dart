import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import '../widgets/kolam_pattern.dart';
import '../widgets/menu_icons.dart';

class AppIntroOnboardingScreen extends StatefulWidget {
  const AppIntroOnboardingScreen({super.key, required this.onComplete});

  final VoidCallback onComplete;

  @override
  State<AppIntroOnboardingScreen> createState() => _AppIntroOnboardingScreenState();
}

class _AppIntroOnboardingScreenState extends State<AppIntroOnboardingScreen>
    with TickerProviderStateMixin {
  final _pageController = PageController();
  late final AnimationController _floatController;
  late final AnimationController _contentController;
  late final AnimationController _pulseController;
  int _page = 0;

  static const _pages = [
    _OnboardingPageData(
      gradient: LinearGradient(
        colors: [Color(0xFF2A0812), AppColors.maroonDark, Color(0xFF8B2340)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
      glowColor: AppColors.gold,
      accent: AppColors.goldLight,
      eyebrow: 'தினசரி பஞ்சாங்கம்',
      illustration: _OnboardingIllustrationKind.calendar,
      title: 'உங்கள் தினசரி\nதமிழ் நாட்காட்டி',
      description:
          'ராசிபலன், சுப முகூர்த்தம், பஞ்சாங்கம் — அனைத்தும் ஒரே இடத்தில். தமிழ் மரபின்படி ஒவ்வொரு நாளையும் திட்டமிடுங்கள்.',
      chips: [
        _OnboardingChip('ராசிபலன்', Icons.auto_awesome_rounded),
        _OnboardingChip('சுப முகூர்த்தம்', Icons.event_available_rounded),
        _OnboardingChip('பஞ்சாங்கம்', Icons.wb_sunny_rounded),
        _OnboardingChip('நல்ல நேரம்', Icons.schedule_rounded),
      ],
    ),
    _OnboardingPageData(
      gradient: LinearGradient(
        colors: [Color(0xFF061510), Color(0xFF0D2818), Color(0xFF1B4332), Color(0xFF2D6A4F)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
      glowColor: Color(0xFF52B788),
      accent: Color(0xFFB7E4C7),
      eyebrow: 'பண மேலாண்மை',
      illustration: _OnboardingIllustrationKind.budget,
      title: 'வரவு & செலவு\nமேலாண்மை',
      description:
          'தினசரி வரவு, செலவுகளை எளிதாக பதிவு செய்து மாதாந்திர சேமிப்பை கண்காணிக்கவும்.',
      chips: [
        _OnboardingChip('வரவு பதிவு', Icons.trending_up_rounded),
        _OnboardingChip('செலவு வகைகள்', Icons.category_rounded),
        _OnboardingChip('மாத அறிக்கை', Icons.bar_chart_rounded),
        _OnboardingChip('சேமிப்பு', Icons.savings_rounded),
      ],
    ),
    _OnboardingPageData(
      gradient: LinearGradient(
        colors: [Color(0xFF0E0824), Color(0xFF1A1040), Color(0xFF2C1F5C), Color(0xFF3D2E7A)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
      glowColor: Color(0xFF9D8DF1),
      accent: Color(0xFFD4C4FF),
      eyebrow: 'இலவச நூலகம்',
      illustration: _OnboardingIllustrationKind.library,
      title: 'தமிழ்\nநூலகம்',
      description:
          'ஆன்மீக நூல்கள், திருக்குறள், பகவத் கீதை — PDF வடிவில் இலவசமாக வாசிக்கவும்.',
      chips: [
        _OnboardingChip('ஆன்மீக நூல்கள்', Icons.auto_stories_rounded),
        _OnboardingChip('திருக்குறள்', Icons.menu_book_rounded),
        _OnboardingChip('PDF வாசிப்பு', Icons.picture_as_pdf_rounded),
        _OnboardingChip('இலவசம்', Icons.volunteer_activism_rounded),
      ],
    ),
    _OnboardingPageData(
      gradient: LinearGradient(
        colors: [Color(0xFF1A0F04), Color(0xFF4A2508), Color(0xFF8B5A14), Color(0xFFC9952D)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
      glowColor: AppColors.gold,
      accent: AppColors.cream,
      eyebrow: 'இன்றைய தகவல்கள்',
      illustration: _OnboardingIllustrationKind.indru,
      title: 'இன்று —\nதினசரி தகவல்கள்',
      description:
          'பிறந்தநாள் பிரபலங்கள், வரலாறு, பொன்மொழிகள் & திருக்குறள் — ஒவ்வொரு நாளும் புதிய அறிவு!',
      chips: [
        _OnboardingChip('பிறந்தநாள்', Icons.cake_rounded),
        _OnboardingChip('வரலாறு', Icons.history_edu_rounded),
        _OnboardingChip('பொன்மொழி', Icons.format_quote_rounded),
        _OnboardingChip('திருக்குறள்', Icons.import_contacts_rounded),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);
    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatController.dispose();
    _contentController.dispose();
    _pulseController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  _OnboardingPageData get _current => _pages[_page];

  Future<void> _finish() async {
    HapticFeedback.lightImpact();
    widget.onComplete();
  }

  void _next() {
    HapticFeedback.selectionClick();
    if (_page < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeOutCubic,
      );
    } else {
      _finish();
    }
  }

  void _onPageChanged(int index) {
    setState(() => _page = index);
    _contentController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _page == _pages.length - 1;
    final data = _current;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: data.gradient.colors.first,
        body: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: _pages.length,
              onPageChanged: _onPageChanged,
              itemBuilder: (context, index) {
                return _OnboardingPage(
                  data: _pages[index],
                  pageIndex: index,
                  pageCount: _pages.length,
                  floatAnimation: _floatController,
                  pulseAnimation: _pulseController,
                  contentAnimation: index == _page ? _contentController : null,
                );
              },
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _OnboardingFooter(
                accent: data.accent,
                glowColor: data.glowColor,
                pageCount: _pages.length,
                pageIndex: _page,
                isLast: isLast,
                onSkip: _finish,
                onNext: _next,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingChip {
  const _OnboardingChip(this.label, this.icon);

  final String label;
  final IconData icon;
}

class _OnboardingPageData {
  const _OnboardingPageData({
    required this.gradient,
    required this.glowColor,
    required this.accent,
    required this.eyebrow,
    required this.illustration,
    required this.title,
    required this.description,
    required this.chips,
  });

  final LinearGradient gradient;
  final Color glowColor;
  final Color accent;
  final String eyebrow;
  final _OnboardingIllustrationKind illustration;
  final String title;
  final String description;
  final List<_OnboardingChip> chips;
}

enum _OnboardingIllustrationKind { calendar, budget, library, indru }

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    required this.data,
    required this.pageIndex,
    required this.pageCount,
    required this.floatAnimation,
    required this.pulseAnimation,
    required this.contentAnimation,
  });

  final _OnboardingPageData data;
  final int pageIndex;
  final int pageCount;
  final Animation<double> floatAnimation;
  final Animation<double> pulseAnimation;
  final AnimationController? contentAnimation;

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.sizeOf(context).height;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final compact = screenH < 740;
    final footerReserve = (compact ? 168.0 : 188.0) + bottomInset;
    final horizontalPad = compact ? 20.0 : 24.0;

    return Container(
      decoration: BoxDecoration(gradient: data.gradient),
      child: KolamPattern(
        opacity: 0.1,
        child: Stack(
          children: [
            _AmbientOrbs(glowColor: data.glowColor, pulseAnimation: pulseAnimation),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(horizontalPad, 4, horizontalPad, footerReserve),
                child: Column(
                  children: [
                    _TopProgressBar(
                      pageIndex: pageIndex,
                      pageCount: pageCount,
                      accent: data.accent,
                      glowColor: data.glowColor,
                    ),
                    SizedBox(height: compact ? 10 : 14),
                    _EyebrowRow(
                      eyebrow: data.eyebrow,
                      pageIndex: pageIndex,
                      pageCount: pageCount,
                      accent: data.accent,
                    ),
                    SizedBox(height: compact ? 10 : 16),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return AnimatedBuilder(
                            animation: floatAnimation,
                            builder: (context, child) {
                              final dy = math.sin(floatAnimation.value * math.pi * 2) * (compact ? 4 : 6);
                              return Transform.translate(
                                offset: Offset(0, dy),
                                child: child,
                              );
                            },
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.center,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: constraints.maxWidth,
                                  maxHeight: constraints.maxHeight,
                                ),
                                child: _OnboardingIllustration(
                                  kind: data.illustration,
                                  accent: data.accent,
                                  glowColor: data.glowColor,
                                  pulseAnimation: pulseAnimation,
                                  compact: compact,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(height: compact ? 8 : 12),
                    _AnimatedContent(
                      controller: contentAnimation,
                      child: _GlassContentCard(
                        accent: data.accent,
                        glowColor: data.glowColor,
                        title: data.title,
                        description: data.description,
                        chips: data.chips,
                        compact: compact,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedContent extends StatelessWidget {
  const _AnimatedContent({required this.controller, required this.child});

  final AnimationController? controller;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (controller == null) return child;

    return AnimatedBuilder(
      animation: CurvedAnimation(parent: controller!, curve: Curves.easeOutCubic),
      builder: (context, child) {
        final t = controller!.value;
        return Transform.translate(
          offset: Offset(0, 24 * (1 - t)),
          child: Opacity(opacity: t.clamp(0.0, 1.0), child: child),
        );
      },
      child: child,
    );
  }
}

class _TopProgressBar extends StatelessWidget {
  const _TopProgressBar({
    required this.pageIndex,
    required this.pageCount,
    required this.accent,
    required this.glowColor,
  });

  final int pageIndex;
  final int pageCount;
  final Color accent;
  final Color glowColor;

  @override
  Widget build(BuildContext context) {
    final progress = (pageIndex + 1) / pageCount;
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        height: 3,
        child: Stack(
          children: [
            Container(color: Colors.white.withValues(alpha: 0.12)),
            AnimatedFractionallySizedBox(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              widthFactor: progress,
              alignment: Alignment.centerLeft,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [accent, glowColor]),
                  boxShadow: [
                    BoxShadow(color: glowColor.withValues(alpha: 0.5), blurRadius: 6),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AmbientOrbs extends StatelessWidget {
  const _AmbientOrbs({required this.glowColor, required this.pulseAnimation});

  final Color glowColor;
  final Animation<double> pulseAnimation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseAnimation,
      builder: (context, _) {
        final scale = 0.92 + pulseAnimation.value * 0.16;
        return Stack(
          children: [
            Positioned(
              top: -80,
              right: -50,
              child: Transform.scale(
                scale: scale,
                child: _GlowOrb(color: glowColor, size: 240, opacity: 0.28),
              ),
            ),
            Positioned(
              top: 140,
              left: -90,
              child: _GlowOrb(color: Colors.white, size: 180, opacity: 0.06),
            ),
            Positioned(
              bottom: 260,
              right: -30,
              child: Transform.scale(
                scale: 1.1 - pulseAnimation.value * 0.1,
                child: _GlowOrb(color: glowColor, size: 140, opacity: 0.18),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({
    required this.color,
    required this.size,
    required this.opacity,
  });

  final Color color;
  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: opacity),
            color.withValues(alpha: 0),
          ],
        ),
      ),
    );
  }
}

class _EyebrowRow extends StatelessWidget {
  const _EyebrowRow({
    required this.eyebrow,
    required this.pageIndex,
    required this.pageCount,
    required this.accent,
  });

  final String eyebrow;
  final int pageIndex;
  final int pageCount;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: accent.withValues(alpha: 0.35)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent,
                  boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.6), blurRadius: 6)],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                eyebrow,
                style: TextStyle(
                  color: accent,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        Text(
          '${pageIndex + 1} / $pageCount',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.55),
            fontWeight: FontWeight.w600,
            fontSize: 13,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

class _GlassContentCard extends StatelessWidget {
  const _GlassContentCard({
    required this.accent,
    required this.glowColor,
    required this.title,
    required this.description,
    required this.chips,
    required this.compact,
  });

  final Color accent;
  final Color glowColor;
  final String title;
  final String description;
  final List<_OnboardingChip> chips;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final cardPad = compact ? 18.0 : 24.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(compact ? 24 : 28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(cardPad, cardPad, cardPad, compact ? 16 : 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.16),
                Colors.white.withValues(alpha: 0.06),
              ],
            ),
            borderRadius: BorderRadius.circular(compact ? 24 : 28),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(
                color: glowColor.withValues(alpha: 0.12),
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 3,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  gradient: LinearGradient(colors: [accent, glowColor]),
                ),
              ),
              SizedBox(height: compact ? 12 : 16),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                      letterSpacing: -0.3,
                      fontSize: compact ? 20 : null,
                    ),
              ),
              SizedBox(height: compact ? 8 : 10),
              Text(
                description,
                maxLines: compact ? 2 : 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.78),
                      height: 1.5,
                      fontWeight: FontWeight.w400,
                      fontSize: compact ? 13 : null,
                    ),
              ),
              SizedBox(height: compact ? 14 : 18),
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _FeatureChip(chip: chips[0], accent: accent, compact: compact)),
                      SizedBox(width: compact ? 6 : 8),
                      Expanded(child: _FeatureChip(chip: chips[1], accent: accent, compact: compact)),
                    ],
                  ),
                  SizedBox(height: compact ? 6 : 8),
                  Row(
                    children: [
                      Expanded(child: _FeatureChip(chip: chips[2], accent: accent, compact: compact)),
                      SizedBox(width: compact ? 6 : 8),
                      Expanded(child: _FeatureChip(chip: chips[3], accent: accent, compact: compact)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({
    required this.chip,
    required this.accent,
    required this.compact,
  });

  final _OnboardingChip chip;
  final Color accent;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: compact ? 8 : 10, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(chip.icon, size: compact ? 16 : 18, color: accent),
          SizedBox(height: compact ? 4 : 5),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              chip.label,
              textAlign: TextAlign.center,
              maxLines: 1,
              style: TextStyle(
                color: accent.withValues(alpha: 0.95),
                fontWeight: FontWeight.w600,
                fontSize: compact ? 11 : 12,
                height: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingFooter extends StatelessWidget {
  const _OnboardingFooter({
    required this.accent,
    required this.glowColor,
    required this.pageCount,
    required this.pageIndex,
    required this.isLast,
    required this.onSkip,
    required this.onNext,
  });

  final Color accent;
  final Color glowColor;
  final int pageCount;
  final int pageIndex;
  final bool isLast;
  final VoidCallback onSkip;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: 0.35),
            Colors.black.withValues(alpha: 0.72),
          ],
          stops: const [0.0, 0.35, 1.0],
        ),
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              24,
              28,
              24,
              20 + MediaQuery.paddingOf(context).bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _PageDots(count: pageCount, index: pageIndex, activeColor: glowColor),
                const SizedBox(height: 20),
                Row(
                  children: [
                    if (!isLast)
                      TextButton(
                        onPressed: onSkip,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white.withValues(alpha: 0.65),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        child: const Text(
                          'தவிர்',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                      )
                    else
                      const SizedBox(width: 72),
                    Expanded(
                      child: _PrimaryButton(
                        label: isLast ? 'தொடங்குங்கள்' : 'அடுத்தது',
                        icon: isLast ? Icons.rocket_launch_rounded : Icons.arrow_forward_rounded,
                        glowColor: glowColor,
                        accent: accent,
                        onTap: onNext,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatefulWidget {
  const _PrimaryButton({
    required this.label,
    required this.icon,
    required this.glowColor,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color glowColor;
  final Color accent;
  final VoidCallback onTap;

  @override
  State<_PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<_PrimaryButton> with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [
            AppColors.maroonDark,
            AppColors.maroon,
            widget.glowColor.withValues(alpha: 0.9),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.glowColor.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            child: Stack(
              children: [
                AnimatedBuilder(
                  animation: _shimmerController,
                  builder: (context, child) {
                    return Positioned.fill(
                      child: Transform.translate(
                        offset: Offset(
                          -120 + _shimmerController.value * 360,
                          0,
                        ),
                        child: Container(
                          width: 80,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                Colors.white.withValues(alpha: 0.15),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 17),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(widget.icon, color: Colors.white, size: 20),
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

class _OnboardingIllustration extends StatelessWidget {
  const _OnboardingIllustration({
    required this.kind,
    required this.accent,
    required this.glowColor,
    required this.pulseAnimation,
    required this.compact,
  });

  final _OnboardingIllustrationKind kind;
  final Color accent;
  final Color glowColor;
  final Animation<double> pulseAnimation;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: switch (kind) {
        _OnboardingIllustrationKind.calendar => _CalendarIllustration(
            accent: accent,
            glowColor: glowColor,
            pulseAnimation: pulseAnimation,
            compact: compact,
          ),
        _OnboardingIllustrationKind.budget => _BudgetIllustration(
            accent: accent,
            glowColor: glowColor,
            compact: compact,
          ),
        _OnboardingIllustrationKind.library => _LibraryIllustration(
            accent: accent,
            glowColor: glowColor,
            pulseAnimation: pulseAnimation,
            compact: compact,
          ),
        _OnboardingIllustrationKind.indru => _IndruIllustration(
            accent: accent,
            glowColor: glowColor,
            compact: compact,
          ),
      },
    );
  }
}

class _CalendarIllustration extends StatelessWidget {
  const _CalendarIllustration({
    required this.accent,
    required this.glowColor,
    required this.pulseAnimation,
    required this.compact,
  });

  final Color accent;
  final Color glowColor;
  final Animation<double> pulseAnimation;
  final bool compact;

  double get _outer => compact ? 190.0 : 210.0;
  double get _mid => compact ? 176.0 : 196.0;
  double get _inner => compact ? 140.0 : 158.0;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseAnimation,
      builder: (context, child) {
        final ringScale = 1.0 + pulseAnimation.value * 0.04;
        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Transform.scale(
              scale: ringScale,
              child: Container(
                width: _outer + 20,
                height: _outer + 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: accent.withValues(alpha: 0.12), width: 1),
                ),
              ),
            ),
            Container(
              width: _outer,
              height: _outer,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: glowColor.withValues(alpha: 0.4),
                    blurRadius: 56,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
            Container(
              width: _mid,
              height: _mid,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: accent.withValues(alpha: 0.45), width: 2),
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.18),
                    Colors.white.withValues(alpha: 0.03),
                  ],
                ),
              ),
            ),
            child!,
          ],
        );
      },
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Container(
            width: _inner,
            height: _inner,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/icon_panchangam.webp',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: AppColors.maroon.withValues(alpha: 0.4),
                  child: const Center(
                    child: MenuIcon(kind: MenuIconKind.panchangam, size: 72, color: AppColors.goldLight),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 4,
            right: 14,
            child: _FloatingBadge(icon: Icons.auto_awesome_rounded, label: 'ராசி', color: accent),
          ),
          Positioned(
            bottom: 8,
            left: 4,
            child: _FloatingBadge(icon: Icons.event_available_rounded, label: 'முகூர்த்தம்', color: accent),
          ),
        ],
      ),
    );
  }
}

class _BudgetIllustration extends StatelessWidget {
  const _BudgetIllustration({
    required this.accent,
    required this.glowColor,
    required this.compact,
  });

  final Color accent;
  final Color glowColor;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: compact ? 260 : 290,
      padding: EdgeInsets.all(compact ? 18 : 22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF0A1410).withValues(alpha: 0.95),
            const Color(0xFF152A20).withValues(alpha: 0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: glowColor.withValues(alpha: 0.25),
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [accent.withValues(alpha: 0.25), accent.withValues(alpha: 0.08)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.account_balance_wallet_rounded, color: accent, size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                'வரவு · செலவு',
                style: TextStyle(color: accent, fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _BudgetStatBox(label: 'வரவு', value: '₹12,500', color: const Color(0xFF95D5B2))),
              const SizedBox(width: 10),
              Expanded(child: _BudgetStatBox(label: 'செலவு', value: '₹8,200', color: const Color(0xFFFFB4A2))),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: 0.65,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              color: const Color(0xFF52B788),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'சேமிப்பு: ₹4,300',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF52B788).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '+34%',
                  style: TextStyle(color: Color(0xFF95D5B2), fontWeight: FontWeight.w800, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BudgetStatBox extends StatelessWidget {
  const _BudgetStatBox({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: color.withValues(alpha: 0.85), fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(color: color, fontSize: 17, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _LibraryIllustration extends StatelessWidget {
  const _LibraryIllustration({
    required this.accent,
    required this.glowColor,
    required this.pulseAnimation,
    required this.compact,
  });

  final Color accent;
  final Color glowColor;
  final Animation<double> pulseAnimation;
  final bool compact;

  static const _bookColors = [
    Color(0xFF7B1A2D),
    Color(0xFF2C1F5C),
    Color(0xFF1B5E3A),
    Color(0xFFB8860B),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: compact ? 180 : 210,
      child: AnimatedBuilder(
        animation: pulseAnimation,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 230,
                height: 230,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: glowColor.withValues(alpha: 0.2 + pulseAnimation.value * 0.12),
                      blurRadius: 48,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              child!,
            ],
          );
        },
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            for (var i = 0; i < 4; i++)
              Transform.translate(
                offset: Offset((i - 1.5) * 26, i * 4.0),
                child: Transform.rotate(
                  angle: (i - 1.5) * 0.12,
                  child: _BookTile(
                    color: _bookColors[i],
                    width: 74 - i * 3.0,
                    height: 110 + i * 6.0,
                  ),
                ),
              ),
            Positioned(
              bottom: -8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: accent.withValues(alpha: 0.4)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 16, offset: const Offset(0, 6)),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.picture_as_pdf_rounded, color: accent, size: 18),
                    const SizedBox(width: 8),
                    Text('PDF வாசிப்பு', style: TextStyle(color: accent, fontWeight: FontWeight.w700, fontSize: 13)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookTile extends StatelessWidget {
  const _BookTile({required this.color, required this.width, required this.height});

  final Color color;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, Color.lerp(color, Colors.black, 0.3)!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.horizontal(left: Radius.circular(3), right: Radius.circular(10)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(4, 10)),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 14),
          Container(width: width * 0.5, height: 2.5, color: Colors.white.withValues(alpha: 0.35)),
          const SizedBox(height: 7),
          Container(width: width * 0.68, height: 2, color: Colors.white.withValues(alpha: 0.2)),
          const Spacer(),
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            width: width * 0.32,
            height: 2,
            color: Colors.white.withValues(alpha: 0.15),
          ),
        ],
      ),
    );
  }
}

class _IndruIllustration extends StatelessWidget {
  const _IndruIllustration({
    required this.accent,
    required this.glowColor,
    required this.compact,
  });

  final Color accent;
  final Color glowColor;
  final bool compact;

  static const _items = [
    (Icons.cake_rounded, 'பிறந்தநாள்'),
    (Icons.history_edu_rounded, 'வரலாறு'),
    (Icons.format_quote_rounded, 'பொன்மொழி'),
    (Icons.menu_book_rounded, 'குறள்'),
  ];

  @override
  Widget build(BuildContext context) {
    final sunSize = compact ? 72.0 : 80.0;
    final gap = compact ? 14.0 : 18.0;
    final rowGap = compact ? 8.0 : 10.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: sunSize,
          height: sunSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [accent, glowColor.withValues(alpha: 0.5)]),
            boxShadow: [
              BoxShadow(color: glowColor.withValues(alpha: 0.5), blurRadius: 32, spreadRadius: 1),
            ],
          ),
          child: Icon(
            Icons.wb_sunny_rounded,
            color: AppColors.maroonDark.withValues(alpha: 0.85),
            size: sunSize * 0.5,
          ),
        ),
        SizedBox(height: gap),
        Row(
          children: [
            Expanded(child: _IndruCard(icon: _items[0].$1, label: _items[0].$2, accent: accent, compact: compact)),
            SizedBox(width: rowGap),
            Expanded(child: _IndruCard(icon: _items[1].$1, label: _items[1].$2, accent: accent, compact: compact)),
          ],
        ),
        SizedBox(height: rowGap),
        Row(
          children: [
            Expanded(child: _IndruCard(icon: _items[2].$1, label: _items[2].$2, accent: accent, compact: compact)),
            SizedBox(width: rowGap),
            Expanded(child: _IndruCard(icon: _items[3].$1, label: _items[3].$2, accent: accent, compact: compact)),
          ],
        ),
      ],
    );
  }
}

class _IndruCard extends StatelessWidget {
  const _IndruCard({
    required this.icon,
    required this.label,
    required this.accent,
    required this.compact,
  });

  final IconData icon;
  final String label;
  final Color accent;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: compact ? 10 : 12, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(compact ? 14 : 18),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(compact ? 6 : 8),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: accent, size: compact ? 18 : 20),
          ),
          SizedBox(height: compact ? 6 : 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: TextStyle(
                color: accent,
                fontWeight: FontWeight.w700,
                fontSize: compact ? 11 : 12,
                height: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingBadge extends StatelessWidget {
  const _FloatingBadge({required this.icon, required this.label, required this.color});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({required this.count, required this.index, required this.activeColor});

  final int count;
  final int index;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 32 : 7,
          height: 7,
          decoration: BoxDecoration(
            gradient: active
                ? LinearGradient(colors: [Colors.white.withValues(alpha: 0.9), activeColor])
                : null,
            color: active ? null : Colors.white.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(4),
            boxShadow: active
                ? [BoxShadow(color: activeColor.withValues(alpha: 0.5), blurRadius: 10)]
                : null,
          ),
        );
      }),
    );
  }
}
