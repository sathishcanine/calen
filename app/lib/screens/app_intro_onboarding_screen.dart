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
  int _page = 0;

  static const _pages = [
    _OnboardingPageData(
      gradient: AppDecorations.heroGradient,
      glowColor: AppColors.gold,
      accent: AppColors.goldLight,
      eyebrow: 'தினசரி பஞ்சாங்கம்',
      illustration: _OnboardingIllustrationKind.calendar,
      title: 'உங்கள் தினசரி\nதமிழ் நாட்காட்டி',
      description:
          'ராசிபலன், சுப முகூர்த்தம், பஞ்சாங்கம், நல்ல நேரம் — அனைத்தும் ஒரே இடத்தில். தமிழ் மரபின்படி ஒவ்வொரு நாளையும் திட்டமிடுங்கள்!',
      chips: [
        _OnboardingChip('ராசிபலன்', Icons.auto_awesome_rounded),
        _OnboardingChip('சுப முகூர்த்தம்', Icons.event_available_rounded),
        _OnboardingChip('பஞ்சாங்கம்', Icons.wb_sunny_rounded),
        _OnboardingChip('நல்ல நேரம்', Icons.schedule_rounded),
      ],
    ),
    _OnboardingPageData(
      gradient: LinearGradient(
        colors: [const Color(0xFF0D1F17), const Color(0xFF1B4332), const Color(0xFF2D6A4F)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      glowColor: const Color(0xFF52B788),
      accent: const Color(0xFFB7E4C7),
      eyebrow: 'பண மேலாண்மை',
      illustration: _OnboardingIllustrationKind.budget,
      title: 'வரவு & செலவு\nமேலாண்மை',
      description:
          'தினசரி வரவு, செலவுகளை எளிதாக பதிவு செய்து, மாதாந்திர சேமிப்பை கண்காணிக்கவும். உங்கள் குடும்ப நலனுக்கான ஸ்மார்ட் பண மேலாளர்!',
      chips: [
        _OnboardingChip('வரவு பதிவு', Icons.trending_up_rounded),
        _OnboardingChip('செலவு வகைகள்', Icons.category_rounded),
        _OnboardingChip('மாத அறிக்கை', Icons.bar_chart_rounded),
        _OnboardingChip('சேமிப்பு', Icons.savings_rounded),
      ],
    ),
    _OnboardingPageData(
      gradient: AppDecorations.spiritualGradient,
      glowColor: const Color(0xFF9D8DF1),
      accent: const Color(0xFFD4C4FF),
      eyebrow: 'இலவச நூலகம்',
      illustration: _OnboardingIllustrationKind.library,
      title: 'தமிழ்\nநூலகம்',
      description:
          'ஆன்மீக நூல்கள், திருக்குறள், பகவத் கீதை, ஜோதிடம் & பல — PDF வடிவில் இலவசமாக வாசிக்கவும். தமிழ் அறிவை வளர்த்துக் கொள்ளுங்கள்!',
      chips: [
        _OnboardingChip('ஆன்மீக நூல்கள்', Icons.auto_stories_rounded),
        _OnboardingChip('திருக்குறள்', Icons.menu_book_rounded),
        _OnboardingChip('PDF வாசிப்பு', Icons.picture_as_pdf_rounded),
        _OnboardingChip('இலவசம்', Icons.volunteer_activism_rounded),
      ],
    ),
    _OnboardingPageData(
      gradient: LinearGradient(
        colors: [const Color(0xFF4A2508), const Color(0xFF8B5A14), const Color(0xFFC9952D)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      glowColor: AppColors.gold,
      accent: AppColors.cream,
      eyebrow: 'இன்றைய தகவல்கள்',
      illustration: _OnboardingIllustrationKind.indru,
      title: 'இன்று —\nதினசரி தகவல்கள்',
      description:
          'பிறந்தநாள் பிரபலங்கள், வரலாற்று நிகழ்வுகள், பொன்மொழிகள், திருக்குறள் & சுவாரஸ்யமான தகவல்கள் — ஒவ்வொரு நாளும் புதிய அறிவு!',
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
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatController.dispose();
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
        duration: const Duration(milliseconds: 480),
        curve: Curves.easeOutCubic,
      );
    } else {
      _finish();
    }
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
              onPageChanged: (index) => setState(() => _page = index),
              itemBuilder: (context, index) {
                return _OnboardingPage(
                  data: _pages[index],
                  pageIndex: index,
                  pageCount: _pages.length,
                  floatAnimation: _floatController,
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
  });

  final _OnboardingPageData data;
  final int pageIndex;
  final int pageCount;
  final Animation<double> floatAnimation;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(gradient: data.gradient),
      child: KolamPattern(
        opacity: 0.14,
        child: Stack(
          children: [
            _AmbientOrbs(glowColor: data.glowColor),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 200),
                child: Column(
                  children: [
                    _EyebrowRow(
                      eyebrow: data.eyebrow,
                      pageIndex: pageIndex,
                      pageCount: pageCount,
                      accent: data.accent,
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: AnimatedBuilder(
                        animation: floatAnimation,
                        builder: (context, child) {
                          final dy = math.sin(floatAnimation.value * math.pi * 2) * 6;
                          return Transform.translate(
                            offset: Offset(0, dy),
                            child: child,
                          );
                        },
                        child: _OnboardingIllustration(
                          kind: data.illustration,
                          accent: data.accent,
                          glowColor: data.glowColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _GlassContentCard(
                      accent: data.accent,
                      title: data.title,
                      description: data.description,
                      chips: data.chips,
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

class _AmbientOrbs extends StatelessWidget {
  const _AmbientOrbs({required this.glowColor});

  final Color glowColor;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -60,
          right: -40,
          child: _GlowOrb(color: glowColor, size: 200, opacity: 0.22),
        ),
        Positioned(
          top: 120,
          left: -70,
          child: _GlowOrb(color: Colors.white, size: 160, opacity: 0.08),
        ),
        Positioned(
          bottom: 280,
          right: -20,
          child: _GlowOrb(color: glowColor, size: 120, opacity: 0.14),
        ),
      ],
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: accent.withValues(alpha: 0.45)),
          ),
          child: Text(
            eyebrow,
            style: TextStyle(
              color: accent,
              fontWeight: FontWeight.w700,
              fontSize: 12,
              letterSpacing: 0.3,
            ),
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${pageIndex + 1} / $pageCount',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

class _GlassContentCard extends StatelessWidget {
  const _GlassContentCard({
    required this.accent,
    required this.title,
    required this.description,
    required this.chips,
  });

  final Color accent;
  final String title;
  final String description;
  final List<_OnboardingChip> chips;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                      letterSpacing: 0.2,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                description,
                textAlign: TextAlign.center,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: chips
                    .map(
                      (chip) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              accent.withValues(alpha: 0.22),
                              Colors.white.withValues(alpha: 0.08),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: accent.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(chip.icon, size: 14, color: accent),
                            const SizedBox(width: 5),
                            Text(
                              chip.label,
                              style: TextStyle(
                                color: accent,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
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
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.fromLTRB(
            24,
            16,
            24,
            16 + MediaQuery.paddingOf(context).bottom,
          ),
          decoration: BoxDecoration(
            color: AppColors.cream.withValues(alpha: 0.92),
            border: Border(
              top: BorderSide(color: glowColor.withValues(alpha: 0.25)),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _PageDots(count: pageCount, index: pageIndex, activeColor: glowColor),
              const SizedBox(height: 18),
              Row(
                children: [
                  if (!isLast)
                    TextButton(
                      onPressed: onSkip,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      ),
                      child: const Text(
                        'தவிர்',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                    )
                  else
                    const SizedBox(width: 72),
                  Expanded(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          colors: [AppColors.maroonDark, AppColors.maroon, glowColor.withValues(alpha: 0.85)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: glowColor.withValues(alpha: 0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: onNext,
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  isLast ? 'தொடங்குங்கள்' : 'அடுத்தது',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  isLast ? Icons.rocket_launch_rounded : Icons.arrow_forward_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
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

class _OnboardingIllustration extends StatelessWidget {
  const _OnboardingIllustration({
    required this.kind,
    required this.accent,
    required this.glowColor,
  });

  final _OnboardingIllustrationKind kind;
  final Color accent;
  final Color glowColor;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: switch (kind) {
        _OnboardingIllustrationKind.calendar => _CalendarIllustration(accent: accent, glowColor: glowColor),
        _OnboardingIllustrationKind.budget => _BudgetIllustration(accent: accent, glowColor: glowColor),
        _OnboardingIllustrationKind.library => _LibraryIllustration(accent: accent, glowColor: glowColor),
        _OnboardingIllustrationKind.indru => _IndruIllustration(accent: accent, glowColor: glowColor),
      },
    );
  }
}

class _CalendarIllustration extends StatelessWidget {
  const _CalendarIllustration({required this.accent, required this.glowColor});

  final Color accent;
  final Color glowColor;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 210,
          height: 210,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: glowColor.withValues(alpha: 0.35),
                blurRadius: 48,
                spreadRadius: 4,
              ),
            ],
          ),
        ),
        Container(
          width: 196,
          height: 196,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: accent.withValues(alpha: 0.5), width: 2.5),
            gradient: RadialGradient(
              colors: [
                Colors.white.withValues(alpha: 0.2),
                Colors.white.withValues(alpha: 0.04),
              ],
            ),
          ),
        ),
        Container(
          width: 158,
          height: 158,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 20,
                offset: const Offset(0, 10),
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
          top: 8,
          right: 18,
          child: _FloatingBadge(icon: Icons.auto_awesome_rounded, label: 'ராசி', color: accent),
        ),
        Positioned(
          bottom: 12,
          left: 8,
          child: _FloatingBadge(icon: Icons.event_available_rounded, label: 'முகூர்த்தம்', color: accent),
        ),
      ],
    );
  }
}

class _BudgetIllustration extends StatelessWidget {
  const _BudgetIllustration({required this.accent, required this.glowColor});

  final Color accent;
  final Color glowColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF0F1A14).withValues(alpha: 0.95),
            const Color(0xFF1B3328).withValues(alpha: 0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: accent.withValues(alpha: 0.45), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: glowColor.withValues(alpha: 0.3),
            blurRadius: 32,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.account_balance_wallet_rounded, color: accent, size: 26),
              ),
              const SizedBox(width: 12),
              Text(
                'வரவு · செலவு',
                style: TextStyle(color: accent, fontWeight: FontWeight.w800, fontSize: 17),
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
              minHeight: 10,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
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
                  color: Colors.white.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF52B788).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _LibraryIllustration extends StatelessWidget {
  const _LibraryIllustration({required this.accent, required this.glowColor});

  final Color accent;
  final Color glowColor;

  static const _bookColors = [
    Color(0xFF7B1A2D),
    Color(0xFF2C1F5C),
    Color(0xFF1B5E3A),
    Color(0xFFB8860B),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: glowColor.withValues(alpha: 0.28), blurRadius: 40, spreadRadius: 2),
              ],
            ),
          ),
          for (var i = 0; i < 4; i++)
            Transform.translate(
              offset: Offset((i - 1.5) * 24, i * 5.0),
              child: Transform.rotate(
                angle: (i - 1.5) * 0.14,
                child: _BookTile(
                  color: _bookColors[i],
                  width: 76 - i * 4.0,
                  height: 108 + i * 8.0,
                ),
              ),
            ),
          Positioned(
            bottom: -4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [accent.withValues(alpha: 0.25), Colors.white.withValues(alpha: 0.1)],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: accent.withValues(alpha: 0.5)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 12, offset: const Offset(0, 4)),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.menu_book_rounded, color: accent, size: 20),
                  const SizedBox(width: 8),
                  Text('PDF வாசிப்பு', style: TextStyle(color: accent, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ),
        ],
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
          colors: [color, Color.lerp(color, Colors.black, 0.25)!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.horizontal(left: Radius.circular(4), right: Radius.circular(10)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 14, offset: const Offset(4, 8)),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(width: width * 0.55, height: 3, color: Colors.white.withValues(alpha: 0.4)),
          const SizedBox(height: 8),
          Container(width: width * 0.72, height: 2, color: Colors.white.withValues(alpha: 0.22)),
          const Spacer(),
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            width: width * 0.35,
            height: 2,
            color: Colors.white.withValues(alpha: 0.18),
          ),
        ],
      ),
    );
  }
}

class _IndruIllustration extends StatelessWidget {
  const _IndruIllustration({required this.accent, required this.glowColor});

  final Color accent;
  final Color glowColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 290,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [accent, glowColor.withValues(alpha: 0.6)]),
              boxShadow: [
                BoxShadow(color: glowColor.withValues(alpha: 0.45), blurRadius: 28, spreadRadius: 2),
              ],
            ),
            child: const Icon(Icons.wb_sunny_rounded, color: AppColors.maroonDark, size: 48),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _IndruCard(emoji: '🎂', label: 'பிறந்தநாள்', accent: accent)),
              const SizedBox(width: 10),
              Expanded(child: _IndruCard(emoji: '📜', label: 'வரலாறு', accent: accent)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _IndruCard(emoji: '💡', label: 'பொன்மொழி', accent: accent)),
              const SizedBox(width: 10),
              Expanded(child: _IndruCard(emoji: '📖', label: 'குறள்', accent: accent)),
            ],
          ),
        ],
      ),
    );
  }
}

class _IndruCard extends StatelessWidget {
  const _IndruCard({required this.emoji, required this.label, required this.accent});

  final String emoji;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white.withValues(alpha: 0.18), Colors.white.withValues(alpha: 0.06)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 26)),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(color: accent, fontWeight: FontWeight.w800, fontSize: 12),
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
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white.withValues(alpha: 0.22), Colors.white.withValues(alpha: 0.1)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withValues(alpha: 0.55)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800),
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
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 28 : 8,
          height: 8,
          decoration: BoxDecoration(
            gradient: active
                ? LinearGradient(colors: [AppColors.maroon, activeColor])
                : null,
            color: active ? null : AppColors.maroon.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(4),
            boxShadow: active
                ? [BoxShadow(color: activeColor.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 2))]
                : null,
          ),
        );
      }),
    );
  }
}
