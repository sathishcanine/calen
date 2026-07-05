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

class _AppIntroOnboardingScreenState extends State<AppIntroOnboardingScreen> {
  final _pageController = PageController();
  int _page = 0;

  static const _pages = [
    _OnboardingPageData(
      gradient: AppDecorations.heroGradient,
      accent: AppColors.goldLight,
      illustration: _OnboardingIllustrationKind.calendar,
      title: 'உங்கள் தினசரி\nதமிழ் நாட்காட்டி',
      description:
          'ராசிபலன், சுப முகூர்த்தம், பஞ்சாங்கம், நல்ல நேரம், கௌரி & கிரக ஓரை — அனைத்தும் ஒரே இடத்தில். தமிழ் மரபின்படி ஒவ்வொரு நாளையும் திட்டமிடுங்கள்!',
      chips: ['ராசிபலன்', 'சுப முகூர்த்தம்', 'பஞ்சாங்கம்', 'நல்ல நேரம்'],
    ),
    _OnboardingPageData(
      gradient: LinearGradient(
        colors: [Color(0xFF1A1A1A), Color(0xFF2D4A3E), Color(0xFF1B5E3A)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      accent: Color(0xFFA8E6CF),
      illustration: _OnboardingIllustrationKind.budget,
      title: 'வரவு & செலவு\nமேலாண்மை',
      description:
          'தினசரி வரவு, செலவுகளை எளிதாக பதிவு செய்து, மாதாந்திர சேமிப்பை கண்காணிக்கவும். உங்கள் குடும்ப நலனுக்கான ஸ்மார்ட் பண மேலாளர்!',
      chips: ['வரவு பதிவு', 'செலவு வகைகள்', 'மாத அறிக்கை', 'சேமிப்பு கண்காணிப்பு'],
    ),
    _OnboardingPageData(
      gradient: AppDecorations.spiritualGradient,
      accent: Color(0xFFB8A9E8),
      illustration: _OnboardingIllustrationKind.library,
      title: 'தமிழ்\nநூலகம்',
      description:
          'ஆன்மீக நூல்கள், திருக்குறள், பகவத் கீதை, ஜோதிடம் & பல — PDF வடிவில் இலவசமாக வாசிக்கவும். தமிழ் அறிவை வளர்த்துக் கொள்ளுங்கள்!',
      chips: ['ஆன்மீக நூல்கள்', 'திருக்குறள்', 'PDF வாசிப்பு', 'இலவசம்'],
    ),
    _OnboardingPageData(
      gradient: LinearGradient(
        colors: [Color(0xFF6B3A10), Color(0xFFB8860B), Color(0xFFD4A853)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      accent: AppColors.cream,
      illustration: _OnboardingIllustrationKind.indru,
      title: 'இன்று —\nதினசரி தகவல்கள்',
      description:
          'பிறந்தநாள் பிரபலங்கள், வரலாற்று நிகழ்வுகள், பொன்மொழிகள், திருக்குறள் & சுவாரஸ்யமான தகவல்கள் — ஒவ்வொரு நாளும் புதிய அறிவு!',
      chips: ['பிறந்தநாள்', 'வரலாறு', 'பொன்மொழி', 'திருக்குறள்'],
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    HapticFeedback.lightImpact();
    widget.onComplete();
  }

  void _next() {
    HapticFeedback.selectionClick();
    if (_page < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
    } else {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _page == _pages.length - 1;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: PageView.builder(
          controller: _pageController,
          itemCount: _pages.length,
          onPageChanged: (index) => setState(() => _page = index),
          itemBuilder: (context, index) {
            final data = _pages[index];
            return _OnboardingPage(data: data);
          },
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(24, 0, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _PageDots(count: _pages.length, index: _page),
              const SizedBox(height: 20),
              Row(
                children: [
                  if (!isLast)
                    TextButton(
                      onPressed: _finish,
                      child: Text(
                        'தவிர்',
                        style: TextStyle(
                          color: AppColors.textSecondary.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 72),
                  Expanded(
                    child: FilledButton(
                      onPressed: _next,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.maroon,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        isLast ? 'தொடங்குங்கள்' : 'அடுத்தது',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
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

class _OnboardingPageData {
  const _OnboardingPageData({
    required this.gradient,
    required this.accent,
    required this.illustration,
    required this.title,
    required this.description,
    required this.chips,
  });

  final LinearGradient gradient;
  final Color accent;
  final _OnboardingIllustrationKind illustration;
  final String title;
  final String description;
  final List<String> chips;
}

enum _OnboardingIllustrationKind { calendar, budget, library, indru }

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.data});

  final _OnboardingPageData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(gradient: data.gradient),
      child: KolamPattern(
        opacity: 0.12,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 12, 28, 120),
            child: Column(
              children: [
                const SizedBox(height: 8),
                _OnboardingIllustration(kind: data.illustration, accent: data.accent),
                const SizedBox(height: 28),
                Text(
                  data.title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                        letterSpacing: 0.2,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                ),
                const SizedBox(height: 16),
                Text(
                  data.description,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withValues(alpha: 0.92),
                        height: 1.55,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: data.chips
                      .map(
                        (chip) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: data.accent.withValues(alpha: 0.45),
                            ),
                          ),
                          child: Text(
                            chip,
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: data.accent,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      )
                      .toList(),
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
  const _OnboardingIllustration({required this.kind, required this.accent});

  final _OnboardingIllustrationKind kind;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: Center(
        child: switch (kind) {
          _OnboardingIllustrationKind.calendar => _CalendarIllustration(accent: accent),
          _OnboardingIllustrationKind.budget => _BudgetIllustration(accent: accent),
          _OnboardingIllustrationKind.library => _LibraryIllustration(accent: accent),
          _OnboardingIllustrationKind.indru => _IndruIllustration(accent: accent),
        },
      ),
    );
  }
}

class _CalendarIllustration extends StatelessWidget {
  const _CalendarIllustration({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: accent.withValues(alpha: 0.35), width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
        ),
        Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                Colors.white.withValues(alpha: 0.18),
                Colors.white.withValues(alpha: 0.04),
              ],
            ),
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/images/icon_panchangam.webp',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const Center(
                child: MenuIcon(kind: MenuIconKind.panchangam, size: 72, color: AppColors.goldLight),
              ),
            ),
          ),
        ),
        Positioned(
          top: 18,
          right: 28,
          child: _FloatingBadge(
            icon: Icons.auto_awesome_rounded,
            label: 'ராசி',
            color: accent,
          ),
        ),
        Positioned(
          bottom: 22,
          left: 24,
          child: _FloatingBadge(
            icon: Icons.event_available_rounded,
            label: 'முகூர்த்தம்',
            color: accent,
          ),
        ),
      ],
    );
  }
}

class _BudgetIllustration extends StatelessWidget {
  const _BudgetIllustration({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accent.withValues(alpha: 0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.15),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.account_balance_wallet_rounded, color: accent, size: 28),
              const SizedBox(width: 10),
              Text(
                'வரவு · செலவு',
                style: TextStyle(
                  color: accent,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _BudgetStatBox(
                  label: 'வரவு',
                  value: '₹12,500',
                  color: const Color(0xFFA8E6CF),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _BudgetStatBox(
                  label: 'செலவு',
                  value: '₹8,200',
                  color: const Color(0xFFFF8B94),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: 0.65,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.12),
              color: const Color(0xFF5CB85C),
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'சேமிப்பு: ₹4,300',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetStatBox extends StatelessWidget {
  const _BudgetStatBox({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _LibraryIllustration extends StatelessWidget {
  const _LibraryIllustration({required this.accent});

  final Color accent;

  static const _bookColors = [
    Color(0xFF7B1A2D),
    Color(0xFF2C1F5C),
    Color(0xFF1B5E3A),
    Color(0xFFB8860B),
  ];

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        for (var i = 0; i < 4; i++)
          Transform.translate(
            offset: Offset((i - 1.5) * 22, i * 4.0),
            child: Transform.rotate(
              angle: (i - 1.5) * 0.12,
              child: _BookTile(
                color: _bookColors[i],
                width: 72 - i * 4.0,
                height: 100 + i * 6.0,
              ),
            ),
          ),
        Positioned(
          bottom: -8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: accent.withValues(alpha: 0.45)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.menu_book_rounded, color: accent, size: 20),
                const SizedBox(width: 8),
                Text(
                  'PDF வாசிப்பு',
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _BookTile extends StatelessWidget {
  const _BookTile({
    required this.color,
    required this.width,
    required this.height,
  });

  final Color color;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.horizontal(
          left: Radius.circular(4),
          right: Radius.circular(8),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(4, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: width * 0.55,
            height: 3,
            color: Colors.white.withValues(alpha: 0.35),
          ),
          const SizedBox(height: 6),
          Container(
            width: width * 0.7,
            height: 2,
            color: Colors.white.withValues(alpha: 0.2),
          ),
        ],
      ),
    );
  }
}

class _IndruIllustration extends StatelessWidget {
  const _IndruIllustration({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [accent, accent.withValues(alpha: 0.5)],
              ),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(Icons.wb_sunny_rounded, color: AppColors.maroonDark, size: 44),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _IndruCard(
                  emoji: '🎂',
                  label: 'பிறந்தநாள்',
                  accent: accent,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _IndruCard(
                  emoji: '📜',
                  label: 'வரலாறு',
                  accent: accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _IndruCard(
                  emoji: '💡',
                  label: 'பொன்மொழி',
                  accent: accent,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _IndruCard(
                  emoji: '📖',
                  label: 'குறள்',
                  accent: accent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IndruCard extends StatelessWidget {
  const _IndruCard({
    required this.emoji,
    required this.label,
    required this.accent,
  });

  final String emoji;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: accent,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingBadge extends StatelessWidget {
  const _FloatingBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active ? AppColors.maroon : AppColors.maroon.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
