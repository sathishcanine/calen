import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../config/ad_config.dart';
import '../models/daily_calendar.dart';
import '../services/calendar_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/native_ad_widget.dart';
import '../widgets/kolam_pattern.dart';
import '../widgets/nav_action_card.dart';
import '../models/palangal.dart';
import '../widgets/jyotish_palangal_menus.dart';
import '../widgets/spiritual_menu_grid.dart';
import 'chandrashtamam_screen.dart';
import 'daily_calendar_screen.dart';
import 'marriage_porutham_screen.dart';
import 'monthly_calendar_screen.dart';
import 'nazhigai_converter_screen.dart';
import 'numerology_screen.dart';
import 'palangal_category_screen.dart';
import 'tarabalam_screen.dart';
import 'gowri_panchangam_screen.dart';
import 'hora_week_screen.dart';
import 'inauspicious_week_screen.dart';
import 'kari_naatkal_screen.dart';
import 'todays_panchangam_screen.dart';
import 'pancha_pakshi_screen.dart';
import 'vastu_screen.dart';

/// SS1 — Home with hero date banner, daily preview, and navigation cards.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.repository});

  final CalendarRepository repository;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  HomeSummary? _home;
  DailyCalendar? _today;
  List<PalangalCategory> _palangalCategories = [];
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final home = await widget.repository.getHome();
      DailyCalendar? today;
      try {
        today = await widget.repository.getDay(home.gregorianDate);
      } catch (_) {}
      List<PalangalCategory> palangal = [];
      try {
        palangal = await widget.repository.getPalangalCategories();
      } catch (_) {}
      if (mounted) {
        setState(() {
          _home = home;
          _today = today;
          _palangalCategories = palangal;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openDailyCalendar(DateTime date) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DailyCalendarScreen(
          repository: widget.repository,
          initialDate: date,
        ),
      ),
    );
  }

  void _openTodaysPanchangam(DateTime date) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TodaysPanchangamScreen(
          repository: widget.repository,
          initialDate: date,
        ),
      ),
    );
  }

  void _openInauspiciousWeek(DateTime date) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InauspiciousWeekScreen(
          repository: widget.repository,
          initialDate: date,
        ),
      ),
    );
  }

  void _openGowriPanchangam(DateTime date) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GowriPanchangamScreen(
          repository: widget.repository,
          initialDate: date,
        ),
      ),
    );
  }

  void _openHoraWeek(DateTime date) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HoraWeekScreen(
          repository: widget.repository,
          initialDate: date,
        ),
      ),
    );
  }

  void _openKariNaatkal(DateTime date) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => KariNaatkalScreen(
          repository: widget.repository,
          initialDate: date,
          year: 2026,
        ),
      ),
    );
  }

  void _openVastu(int year) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VastuScreen(
          repository: widget.repository,
          initialYear: year,
        ),
      ),
    );
  }

  void _openPanchaPakshi(DateTime date) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PanchaPakshiScreen(
          repository: widget.repository,
          initialDate: date,
        ),
      ),
    );
  }

  void _openMarriagePorutham() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MarriagePoruthamScreen(repository: widget.repository)),
    );
  }

  void _openNumerology() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => NumerologyScreen(repository: widget.repository)),
    );
  }

  void _openNazhigai(DateTime date) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NazhigaiConverterScreen(repository: widget.repository, initialDate: date),
      ),
    );
  }

  void _openChandrashtamam(DateTime date) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChandrashtamamScreen(repository: widget.repository, initialDate: date),
      ),
    );
  }

  void _openPalangalCategory(PalangalCategory category, DateTime date) {
    if (category.id == 'tara') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TarabalamScreen(repository: widget.repository, initialDate: date),
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PalangalCategoryScreen(
          repository: widget.repository,
          categoryId: category.id,
          titleTa: category.titleTa,
          initialDate: date,
          isCalculator: category.isCalculator,
        ),
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'காலை வணக்கம்';
    if (hour < 17) return 'மதிய வணக்கம்';
    return 'மாலை வணக்கம்';
  }

  List<PalangalCategory> _defaultPalangalCategories() => const [
        PalangalCategory(id: 'kanavu', titleTa: 'கனவு பலன்கள்', subtitleTa: '', icon: 'bedtime', color: '#FF6F00'),
        PalangalCategory(id: 'palli_vizhum', titleTa: 'பல்லி விழும் பலன்கள்', subtitleTa: '', icon: 'pest_control', color: '#1565C0'),
        PalangalCategory(id: 'palli_sollum', titleTa: 'பல்லி சொல்லும் பலன்கள்', subtitleTa: '', icon: 'record_voice_over', color: '#EF6C00'),
        PalangalCategory(id: 'manaiyadi', titleTa: 'மனையடி சாஸ்திரம்', subtitleTa: '', icon: 'home_work', color: '#AD1457'),
        PalangalCategory(id: 'tara', titleTa: 'தாரா பலன்கள்', subtitleTa: '', icon: 'stars', color: '#6A1B9A', kind: 'calculator'),
        PalangalCategory(id: 'macha', titleTa: 'மச்ச பலன்கள்', subtitleTa: '', icon: 'face', color: '#C62828'),
        PalangalCategory(id: 'dhana', titleTa: 'தான பலன்கள்', subtitleTa: '', icon: 'volunteer_activism', color: '#7B1FA2'),
        PalangalCategory(id: 'vilakku', titleTa: 'விளக்கு ஏற்றும் பலன்கள்', subtitleTa: '', icon: 'light_mode', color: '#558B2F'),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: NativeAdWidget(adUnitId: AdConfig.homeNativeUnitId),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorView(error: _error!, onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.maroon,
                  child: CustomScrollView(
                    slivers: [
                      SliverAppBar(
                        floating: true,
                        pinned: true,
                        backgroundColor: AppColors.cream,
                        foregroundColor: AppColors.maroon,
                        centerTitle: false,
                        titleSpacing: 16,
                        title: Text(
                          'A-Z தமிழ்',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: AppColors.maroon,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        actions: [
                          IconButton(
                            icon: const Icon(Icons.refresh_rounded),
                            tooltip: 'புதுப்பிக்க',
                            onPressed: _load,
                          ),
                        ],
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _greeting(),
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                              ),
                              const SizedBox(height: 16),
                              _HeroDateCard(
                                home: _home!,
                                today: _today,
                                onTap: () => _openDailyCalendar(_home!.gregorianDate),
                              ),
                              if (_today != null) ...[
                                const SizedBox(height: 20),
                                _TodayPreview(
                                  day: _today!,
                                  onTap: () => _openDailyCalendar(_home!.gregorianDate),
                                ),
                              ],
                              const SizedBox(height: 24),
                              SpiritualMenuGrid(
                                onOpenPanchangam: () => _openTodaysPanchangam(_home!.gregorianDate),
                                onOpenInauspicious: () => _openInauspiciousWeek(_home!.gregorianDate),
                                onOpenGowri: () => _openGowriPanchangam(_home!.gregorianDate),
                                onOpenHora: () => _openHoraWeek(_home!.gregorianDate),
                                onOpenKariNaatkal: () => _openKariNaatkal(_home!.gregorianDate),
                                onOpenVastu: () => _openVastu(_home!.gregorianDate.year),
                                onOpenPanchaPakshi: () => _openPanchaPakshi(_home!.gregorianDate),
                              ),
                              const SizedBox(height: 24),
                              JyotishPalangalMenus(
                                jyotishItems: [
                                  JyotishMenuItem(
                                    label: 'திருமண பொருத்தம்',
                                    icon: Icons.favorite_rounded,
                                    color: const Color(0xFF2E8B57),
                                    onTap: _openMarriagePorutham,
                                  ),
                                  JyotishMenuItem(
                                    label: 'எண்கணிதம்',
                                    icon: Icons.pin_rounded,
                                    color: const Color(0xFFC62828),
                                    onTap: _openNumerology,
                                  ),
                                  JyotishMenuItem(
                                    label: 'நாழிகை converter',
                                    icon: Icons.access_time_filled_rounded,
                                    color: const Color(0xFFF9A825),
                                    onTap: () => _openNazhigai(_home!.gregorianDate),
                                  ),
                                  JyotishMenuItem(
                                    label: 'சந்திராஷ்டமம்',
                                    icon: Icons.nightlight_round,
                                    color: const Color(0xFF1565C0),
                                    onTap: () => _openChandrashtamam(_home!.gregorianDate),
                                  ),
                                ],
                                palangalItems: (_palangalCategories.isNotEmpty
                                        ? _palangalCategories
                                        : _defaultPalangalCategories())
                                    .map(
                                      (c) => PalangalMenuItem(
                                        id: c.id,
                                        label: c.titleTa,
                                        icon: palangalIconFromName(c.icon),
                                        color: palangalColorFromHex(c.color),
                                        kind: c.kind,
                                        onTap: () => _openPalangalCategory(c, _home!.gregorianDate),
                                      ),
                                    )
                                    .toList(),
                              ),
                              const SizedBox(height: 28),
                              Text(
                                'காலண்டர்',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 1,
                                    ),
                              ),
                              const SizedBox(height: 12),
                              NavActionCard(
                                gradient: const [AppColors.dailyRed, AppColors.dailyRedLight],
                                icon: Icons.wb_sunny_rounded,
                                title: 'நாள் காட்டி',
                                subtitle: 'பஞ்சாங்கம் · ராசிபலன் · நல்ல நேரம்',
                                onTap: () => _openDailyCalendar(_home!.gregorianDate),
                              ),
                              const SizedBox(height: 14),
                              NavActionCard(
                                gradient: const [AppColors.monthlyGreen, AppColors.monthlyGreenLight],
                                icon: Icons.calendar_month_rounded,
                                title: 'மாத காட்டி',
                                subtitle: 'விரதம் · பண்டிகை · சுபமுகூர்த்தம்',
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => MonthlyCalendarScreen(
                                      repository: widget.repository,
                                      year: _home!.gregorianDate.year,
                                      month: _home!.gregorianDate.month,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 28),
                              Center(
                                child: Text(
                                  'தமிழ் மரபு · தினசரி வழிகாட்டி',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: AppColors.textSecondary.withValues(alpha: 0.7),
                                        fontStyle: FontStyle.italic,
                                      ),
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

class _HeroDateCard extends StatelessWidget {
  const _HeroDateCard({
    required this.home,
    required this.today,
    required this.onTap,
  });

  final HomeSummary home;
  final DailyCalendar? today;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final parts = home.gregorianDisplay.split('-');
    final dayNum = parts.isNotEmpty ? parts[0] : '';
    final monthYear = parts.length >= 3 ? '${parts[1]}-${parts[2]}' : home.gregorianDisplay;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            gradient: AppDecorations.heroGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.greenBanner.withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: KolamPattern(
            opacity: 0.12,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.goldLight.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      home.bannerLineTa,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: AppColors.goldLight,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        dayNum,
                        style: Theme.of(context).textTheme.displayLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              height: 1,
                              fontSize: 72,
                            ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12, left: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              monthYear,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            if (today != null)
                              Text(
                                today!.subtitleLine2Ta,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.white70,
                                    ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (today != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      today!.subtitleLine1Ta,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.touch_app_rounded, color: AppColors.goldLight, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'முழு விவரம் பார்க்க',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: AppColors.goldLight,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TodayPreview extends StatelessWidget {
  const _TodayPreview({required this.day, required this.onTap});

  final DailyCalendar day;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      goldAccent: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDecorations.cardRadius),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.maroon.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.auto_awesome, color: AppColors.maroon, size: 20),
                ),
                const SizedBox(width: 10),
                Text(
                  'இன்றைய சிறப்பு',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.maroon,
                      ),
                ),
              ],
            ),
            if (day.eventsTa.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                day.eventsTa,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
              ),
            ],
            if (day.nallaNeram.isNotEmpty) ...[
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.schedule_rounded, color: AppColors.auspicious, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'நல்ல நேரம்',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppColors.auspicious,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...day.nallaNeram.map(
                (s) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(s.period, style: TextStyle(color: AppColors.textSecondary)),
                      Text(
                        s.time,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.auspicious),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (day.quoteTa.isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.creamDark.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(AppDecorations.cardRadiusSm),
                  border: Border(left: BorderSide(color: AppColors.gold, width: 3)),
                ),
                child: Text(
                  '"${day.quoteTa}"',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                        height: 1.5,
                        color: AppColors.textPrimary,
                      ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: AppCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.maroon.withValues(alpha: 0.6)),
              const SizedBox(height: 16),
              Text(
                'இணைப்பு தோல்வி',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(error, textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              Text(
                AppConfig.offlineMode
                    ? 'ஆஃப்லைன்: சென்னை 2026 தரவு மட்டும். வேறு தேதிகள் இல்லை.'
                    : 'API: uvicorn app.main:app --reload --host 0.0.0.0 --port 4000',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('மீண்டும் முயற்சி'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.maroon,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
