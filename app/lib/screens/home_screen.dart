import 'package:flutter/material.dart';

import '../models/daily_calendar.dart';
import '../models/indru_content.dart';
import '../services/calendar_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/aanmeegam_menu_grid.dart';
import '../widgets/app_card.dart';
import '../widgets/kolam_pattern.dart';
import '../widgets/nav_action_card.dart';
import '../models/palangal.dart';
import '../models/status_story.dart';
import '../services/status_story_service.dart';
import '../widgets/jyotish_palangal_menus.dart';
import '../widgets/metal_rates_menu_card.dart';
import '../widgets/status_stories_bar.dart';
import '../widgets/spiritual_menu_grid.dart';
import '../widgets/menu_icons.dart';
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
import 'jyotisha_search_screen.dart';
import 'kari_naatkal_screen.dart';
import 'metal_rates_screen.dart';
import 'todays_panchangam_screen.dart';
import 'pancha_pakshi_screen.dart';
import 'temples/temples_screen.dart';
import 'vastu_screen.dart';
import '../models/koodiya_thagaval_post.dart';
import '../widgets/koodiya_thagaval_section.dart';
import 'budget/budget_screen.dart';
import 'library/library_screen.dart';
import 'raasi_palan_hub_screen.dart';
import '../widgets/zodiac_sign_icon.dart';

/// SS1 — Home with hero date banner, daily preview, and navigation cards.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.repository});

  final CalendarRepository repository;

  /// Bottom nav index for the வரவு செலவு tab.
  static const int budgetTabIndex = 3;

  /// Bottom nav index for the இன்று tab.
  static const int indruTabIndex = 4;

  /// Set from [_HomeScreenState] so notification taps can switch tabs.
  static void Function(int tabIndex)? switchToTab;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  HomeSummary? _home;
  DailyCalendar? _today;
  List<PalangalCategory> _palangalCategories = [];
  List<StatusStory> _statusStories = [];
  Set<String> _viewedStoryIds = {};
  bool _statusStoriesLoading = true;
  IndruContent? _indru;
  bool _indruLoading = true;
  List<KoodiyaThagavalPost> _koodiyaThagavalPosts = [];
  bool _koodiyaThagavalLoading = true;
  String? _error;
  bool _loading = true;
  int _navIndex = 0;

  @override
  void initState() {
    super.initState();
    HomeScreen.switchToTab = _switchToTab;
    _load();
    _loadStatusStories();
    _loadIndru();
    _loadKoodiyaThagaval();
  }

  @override
  void dispose() {
    if (HomeScreen.switchToTab == _switchToTab) {
      HomeScreen.switchToTab = null;
    }
    super.dispose();
  }

  void _switchToTab(int index) {
    if (!mounted) return;
    if (index < 0 || index > 4) return;
    setState(() => _navIndex = index);
  }

  Future<void> _loadKoodiyaThagaval() async {
    setState(() => _koodiyaThagavalLoading = true);
    try {
      final posts = await widget.repository.getKoodiyaThagavalPosts();
      if (mounted) setState(() => _koodiyaThagavalPosts = posts);
    } catch (_) {
      if (mounted) setState(() => _koodiyaThagavalPosts = const []);
    } finally {
      if (mounted) setState(() => _koodiyaThagavalLoading = false);
    }
  }

  Future<void> _loadIndru() async {
    setState(() => _indruLoading = true);
    try {
      final indru = await widget.repository.getIndru(
        date: _home?.gregorianDate ?? DateTime.now(),
      );
      if (mounted) setState(() => _indru = indru);
    } catch (_) {
      if (mounted) setState(() => _indru = IndruContent.empty);
    } finally {
      if (mounted) setState(() => _indruLoading = false);
    }
  }

  Future<void> _loadStatusStories() async {
    setState(() => _statusStoriesLoading = true);
    try {
      final stories = await widget.repository.getStatusStories();
      final viewed = await StatusStoryService.instance.getViewedIds();
      if (mounted) {
        setState(() {
          _statusStories = stories;
          _viewedStoryIds = viewed;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _statusStories = []);
    } finally {
      if (mounted) setState(() => _statusStoriesLoading = false);
    }
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
        _loadIndru();
        _loadKoodiyaThagaval();
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openMetalRates() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MetalRatesScreen(repository: widget.repository),
      ),
    );
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
        builder: (_) =>
            HoraWeekScreen(repository: widget.repository, initialDate: date),
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
        builder: (_) =>
            VastuScreen(repository: widget.repository, initialYear: year),
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

  void _openTemples() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TemplesScreen(repository: widget.repository),
      ),
    );
  }

  void _openMarriagePorutham() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MarriagePoruthamScreen(repository: widget.repository),
      ),
    );
  }

  void _openNumerology() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NumerologyScreen(repository: widget.repository),
      ),
    );
  }

  void _openNazhigai(DateTime date) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NazhigaiConverterScreen(
          repository: widget.repository,
          initialDate: date,
        ),
      ),
    );
  }

  void _openChandrashtamam(DateTime date) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChandrashtamamScreen(
          repository: widget.repository,
          initialDate: date,
        ),
      ),
    );
  }

  void _openPalangalCategory(PalangalCategory category, DateTime date) {
    if (category.id == 'tara') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              TarabalamScreen(repository: widget.repository, initialDate: date),
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
    PalangalCategory(
      id: 'guru_peyarchi',
      titleTa: 'குரு பெயர்ச்சி',
      subtitleTa: '',
      icon: 'stars',
      color: '#2E7D32',
    ),
    PalangalCategory(
      id: 'sani_peyarchi',
      titleTa: 'சனிப் பெயர்ச்சி',
      subtitleTa: '',
      icon: 'schedule',
      color: '#E65100',
    ),
    PalangalCategory(
      id: 'rahu_ketu_peyarchi',
      titleTa: 'ராகு கேது பெயர்ச்சி',
      subtitleTa: '',
      icon: 'blur_on',
      color: '#6A1B9A',
    ),
    PalangalCategory(
      id: 'kanavu',
      titleTa: 'கனவு பலன்கள்',
      subtitleTa: '',
      icon: 'bedtime',
      color: '#FF6F00',
    ),
    PalangalCategory(
      id: 'palli_vizhum',
      titleTa: 'பல்லி விழும் பலன்கள்',
      subtitleTa: '',
      icon: 'pest_control',
      color: '#1565C0',
    ),
    PalangalCategory(
      id: 'tara',
      titleTa: 'தாரா பலன்கள்',
      subtitleTa: '',
      icon: 'stars',
      color: '#6A1B9A',
      kind: 'calculator',
    ),
    PalangalCategory(
      id: 'manaiyadi',
      titleTa: 'மனையடி சாஸ்திரம்',
      subtitleTa: '',
      icon: 'home_work',
      color: '#AD1457',
    ),
    PalangalCategory(
      id: 'vilakku',
      titleTa: 'விளக்கு ஏற்றும் பலன்கள்',
      subtitleTa: '',
      icon: 'light_mode',
      color: '#558B2F',
    ),
    PalangalCategory(
      id: 'kaagam',
      titleTa: 'காகம் கரையும் பலன்கள்',
      subtitleTa: '',
      icon: 'pets',
      color: '#4E342E',
    ),
    PalangalCategory(
      id: 'dhana',
      titleTa: 'தான பலன்கள்',
      subtitleTa: '',
      icon: 'volunteer_activism',
      color: '#7B1FA2',
    ),
    PalangalCategory(
      id: 'macha',
      titleTa: 'மச்ச பலன்கள்',
      subtitleTa: '',
      icon: 'face',
      color: '#C62828',
    ),
    PalangalCategory(
      id: 'thummal',
      titleTa: 'தும்மல் சகுனம்',
      subtitleTa: '',
      icon: 'air',
      color: '#00838F',
    ),
    PalangalCategory(
      id: 'palli_sollum',
      titleTa: 'பல்லி சொல்லும் பலன்கள்',
      subtitleTa: '',
      icon: 'record_voice_over',
      color: '#EF6C00',
    ),
    PalangalCategory(
      id: 'navagraha',
      titleTa: 'நவகிரக பலன்கள்',
      subtitleTa: '',
      icon: 'blur_circular',
      color: '#B71C1C',
    ),
    PalangalCategory(
      id: 'jyotidar_padigal',
      titleTa: 'ஜோதிடர் பதில்கள்',
      subtitleTa: '',
      icon: 'psychology',
      color: '#37474F',
    ),
  ];

  List<PalangalCategory> _allPalangalCategories() =>
      _palangalCategories.isNotEmpty
      ? _palangalCategories
      : _defaultPalangalCategories();

  PalangalCategory? _palangalById(String id) {
    for (final c in _allPalangalCategories()) {
      if (c.id == id) return c;
    }
    return null;
  }

  void _openJyotishaSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => JyotishaSearchScreen(
          repository: widget.repository,
          initialDate: _home!.gregorianDate,
        ),
      ),
    );
  }

  AanmeegamMenuItem _palangalMenuItem(
    PalangalCategory category, {
    String? labelOverride,
  }) {
    return AanmeegamMenuItem(
      label: labelOverride ?? category.titleTa,
      iconKind: menuIconKindFromPalangalId(category.id),
      gradient: palangalGradientFromHex(category.color),
      onTap: () => _openPalangalCategory(category, _home!.gregorianDate),
    );
  }

  List<AanmeegamMenuItem> _aanmeegamSpiritualItems() => [
    AanmeegamMenuItem(
      label: 'இன்றைய பஞ்சாங்கம்',
      iconKind: MenuIconKind.panchangam,
      gradient: AppDecorations.spiritualGradient,
      imageAsset: 'assets/images/icon_panchangam.webp',
      onTap: () => _openTodaysPanchangam(_home!.gregorianDate),
    ),
    AanmeegamMenuItem(
      label: 'ராகு, குளிகை, எமகண்டம்',
      iconKind: MenuIconKind.inauspicious,
      gradient: AppDecorations.tealGradient,
      onTap: () => _openInauspiciousWeek(_home!.gregorianDate),
    ),
    AanmeegamMenuItem(
      label: 'கௌரி பஞ்சாங்கம்',
      iconKind: MenuIconKind.gowri,
      gradient: AppDecorations.forestGradient,
      onTap: () => _openGowriPanchangam(_home!.gregorianDate),
    ),
    AanmeegamMenuItem(
      label: 'கிரக ஓரைகளின் காலம்',
      iconKind: MenuIconKind.hora,
      gradient: const LinearGradient(
        colors: [Color(0xFF8B1A1A), Color(0xFFC62828)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      onTap: () => _openHoraWeek(_home!.gregorianDate),
    ),
    AanmeegamMenuItem(
      label: 'கரி நாட்கள், அஷ்டமி, நவமி',
      iconKind: MenuIconKind.kariNaatkal,
      gradient: const LinearGradient(
        colors: [Color(0xFF6B4F0A), Color(0xFF8B6914)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      onTap: () => _openKariNaatkal(_home!.gregorianDate),
    ),
    AanmeegamMenuItem(
      label: 'வாஸ்து தகவல்/நாட்கள்',
      iconKind: MenuIconKind.vastu,
      gradient: const LinearGradient(
        colors: [Color(0xFF3E2723), Color(0xFF5D4037)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      imageAsset: 'assets/images/icon_temple.webp',
      onTap: () => _openVastu(_home!.gregorianDate.year),
    ),
    AanmeegamMenuItem(
      label: 'பிரபல கோவில்கள்',
      iconKind: MenuIconKind.vastu,
      gradient: const LinearGradient(
        colors: [Color(0xFF512DA8), Color(0xFF7E57C2)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      imageAsset: 'assets/images/icon_temple.webp',
      onTap: _openTemples,
    ),
    AanmeegamMenuItem(
      label: 'ஜோதிடர் பதில்கள்',
      iconKind: MenuIconKind.marriage,
      gradient: const LinearGradient(
        colors: [Color(0xFF37474F), Color(0xFF546E7A)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      onTap: () {
        final c = _palangalById('jyotidar_padigal');
        if (c != null) _openPalangalCategory(c, _home!.gregorianDate);
      },
    ),
    AanmeegamMenuItem(
      label: 'ஜோதிட தேடல்',
      icon: Icons.manage_search_rounded,
      gradient: const LinearGradient(
        colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      onTap: _openJyotishaSearch,
    ),
  ];

  List<AanmeegamMenuItem> _aanmeegamPalangalItems() {
    const orderedIds = [
      'guru_peyarchi',
      'sani_peyarchi',
      'rahu_ketu_peyarchi',
      'kanavu',
      'palli_vizhum',
      'tara',
      'manaiyadi',
      'vilakku',
      'kaagam',
      'dhana',
      'macha',
      'thummal',
      'palli_sollum',
      'navagraha',
    ];

    final items = <AanmeegamMenuItem>[];
    for (final id in orderedIds) {
      final category = _palangalById(id);
      if (category != null) {
        final label = id == 'tara' ? 'தாரா பலன்' : category.titleTa;
        items.add(_palangalMenuItem(category, labelOverride: label));
      }
    }

    items.insert(
      5,
      AanmeegamMenuItem(
        label: 'பஞ்ச பட்சி சாஸ்திரம்/கணக்கீடு',
        iconKind: MenuIconKind.panchaPakshi,
        gradient: const LinearGradient(
          colors: [Color(0xFFE65100), Color(0xFFF9A825)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        onTap: () => _openPanchaPakshi(_home!.gregorianDate),
      ),
    );

    return items;
  }

  List<JyotishMenuItem> _jyotishItems() => [
    JyotishMenuItem(
      label: 'திருமண பொருத்தம்',
      iconKind: MenuIconKind.marriage,
      gradient: AppDecorations.forestGradient,
      onTap: _openMarriagePorutham,
    ),
    JyotishMenuItem(
      label: 'எண்கணிதம்',
      iconKind: MenuIconKind.numerology,
      gradient: const LinearGradient(
        colors: [Color(0xFF8B1A1A), Color(0xFFC62828)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      onTap: _openNumerology,
    ),
    JyotishMenuItem(
      label: 'நாழிகை converter',
      iconKind: MenuIconKind.nazhigai,
      gradient: const LinearGradient(
        colors: [Color(0xFFE65100), Color(0xFFF9A825)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      onTap: () => _openNazhigai(_home!.gregorianDate),
    ),
    JyotishMenuItem(
      label: 'சந்திராஷ்டமம்',
      iconKind: MenuIconKind.chandrashtamam,
      gradient: const LinearGradient(
        colors: [Color(0xFF0D3B66), Color(0xFF1565C0)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      onTap: () => _openChandrashtamam(_home!.gregorianDate),
    ),
  ];

  List<PalangalMenuItem> _palangalItems() => _allPalangalCategories()
      .map(
        (c) => PalangalMenuItem(
          id: c.id,
          label: c.titleTa,
          iconKind: menuIconKindFromPalangalId(c.id),
          gradient: palangalGradientFromHex(c.color),
          kind: c.kind,
          onTap: () => _openPalangalCategory(c, _home!.gregorianDate),
        ),
      )
      .toList();

  Widget _buildTabContent() {
    switch (_navIndex) {
      case 0:
        return _buildMugappuTab();
      case 1:
        return _buildAanmeegamTab();
      case 2:
        return _buildPadhivugalTab();
      case 3:
        return _buildStatusTab();
      case 4:
        return _buildIndruTab();
      default:
        return _buildMugappuTab();
    }
  }

  Widget _buildCalendarCards() {
    return SizedBox(
      height: 130,
      child: Row(
        children: [
          Expanded(
            child: NavActionCard(
              compact: true,
              gradient: const [AppColors.dailyRed, AppColors.dailyRedLight],
              iconKind: MenuIconKind.dailyCalendar,
              title: 'நாள் காட்டி',
              subtitle: 'பஞ்சாங்கம் · ராசிபலன்',
              onTap: () => _openDailyCalendar(_home!.gregorianDate),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: NavActionCard(
              compact: true,
              gradient: const [
                AppColors.monthlyGreen,
                AppColors.monthlyGreenLight,
              ],
              iconKind: MenuIconKind.monthlyCalendar,
              title: 'மாத காட்டி',
              subtitle: 'விரதம் · பண்டிகை',
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
          ),
        ],
      ),
    );
  }

  Widget _buildMugappuTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_statusStoriesLoading) ...[
          const StatusStoriesBarSkeleton(),
          const SizedBox(height: 16),
        ] else if (_statusStories.isNotEmpty) ...[
          StatusStoriesBar(
            stories: _statusStories,
            viewedIds: _viewedStoryIds,
            onViewed: () async {
              final viewed = await StatusStoryService.instance.getViewedIds();
              if (mounted) setState(() => _viewedStoryIds = viewed);
            },
          ),
          const SizedBox(height: 16),
        ],
        _HeroDateCard(
          home: _home!,
          today: _today,
          onTap: () => _openDailyCalendar(_home!.gregorianDate),
        ),
        const SizedBox(height: 16),
        _RaasiPalanHomeCard(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RaasiPalanHubScreen(
                repository: widget.repository,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildCalendarCards(),
        const SizedBox(height: 20),
        MetalRatesMenuCard(onTap: _openMetalRates),
        const SizedBox(height: 14),
        _TempleHeroButton(onTap: _openTemples),
        const SizedBox(height: 24),
        SpiritualMenuGrid(
          onOpenPanchangam: () => _openTodaysPanchangam(_home!.gregorianDate),
          onOpenInauspicious: () => _openInauspiciousWeek(_home!.gregorianDate),
          onOpenGowri: () => _openGowriPanchangam(_home!.gregorianDate),
          onOpenHora: () => _openHoraWeek(_home!.gregorianDate),
          onOpenKariNaatkal: () => _openKariNaatkal(_home!.gregorianDate),
          onOpenVastu: () => _openVastu(_home!.gregorianDate.year),
          onOpenPanchaPakshi: () => _openPanchaPakshi(_home!.gregorianDate),
          onOpenTemples: _openTemples,
        ),
        const SizedBox(height: 24),
        JyotishPalangalMenus(
          jyotishItems: _jyotishItems(),
          palangalItems: _palangalItems(),
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
    );
  }

  Widget _buildAanmeegamTab() {
    return AanmeegamMenuGrid(
      spiritualItems: _aanmeegamSpiritualItems(),
      palangalItems: _aanmeegamPalangalItems(),
      jyotishItems: _jyotishItems(),
      onOpenTemples: _openTemples,
    );
  }

  Widget _buildPadhivugalTab() {
    return LibraryScreen(repository: widget.repository);
  }

  Widget _buildStatusTab() {
    return const BudgetScreen();
  }

  Widget _buildIndruTab() {
    final indru = _indru;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_indruLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (indru != null && indru.hasContent) ...[
          if (indru.birthdayTa.isNotEmpty)
            _IndruSectionCard(
              emoji: '🎂',
              title: 'இன்றைய பிறந்தநாள் பிரபலங்கள்',
              body: indru.birthdayTa,
              detail: indru.birthdayDetailTa,
            ),
          if (indru.historicEventTa.isNotEmpty) ...[
            const SizedBox(height: 12),
            _IndruSectionCard(
              emoji: '📜',
              title: 'இன்று நடந்த வரலாற்று நிகழ்வு',
              body: indru.historicEventTa,
              detail: indru.historicEventDetailTa,
            ),
          ],
          if (indru.factTa.isNotEmpty) ...[
            const SizedBox(height: 12),
            _IndruSectionCard(
              emoji: '🧠',
              title: 'இன்று ஒரு தகவல்',
              body: indru.factTa,
            ),
          ],
          if (indru.quoteTa.isNotEmpty) ...[
            const SizedBox(height: 12),
            _IndruSectionCard(
              emoji: '💡',
              title: 'இன்று ஒரு பொன்மொழி',
              body: indru.quoteTa,
              detail: indru.quoteAuthorTa.isNotEmpty
                  ? '— ${indru.quoteAuthorTa}'
                  : '',
              italicBody: true,
            ),
          ],
          if (indru.kuralTa.isNotEmpty) ...[
            const SizedBox(height: 12),
            _IndruSectionCard(
              emoji: '📖',
              title: 'திருக்குறள் #${indru.kuralNumber}',
              body: indru.kuralTa,
              detail: indru.kuralMeaningTa,
            ),
          ],
          const SizedBox(height: 16),
        ] else if (indru != null) ...[
          AppCard(
            child: Text(
              'இன்றைய உள்ளடக்கம் விரைவில் புதுப்பிக்கப்படும்.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 16),
        ],
        KoodiyaThagavalSection(
          repository: widget.repository,
          posts: _koodiyaThagavalPosts,
          loading: _koodiyaThagavalLoading,
        ),
        if (!_koodiyaThagavalLoading && _koodiyaThagavalPosts.isNotEmpty)
          const SizedBox(height: 16),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _openTodaysPanchangam(_home!.gregorianDate),
            borderRadius: BorderRadius.circular(18),
            child: Ink(
              decoration: BoxDecoration(
                gradient: AppDecorations.spiritualGradient,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: AppDecorations.spiritualGradient.colors.first
                        .withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.goldLight.withValues(alpha: 0.4),
                        ),
                      ),
                      child: const Center(
                        child: MenuIcon(
                          kind: MenuIconKind.panchangam,
                          size: 28,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'இன்றைய பஞ்சாங்கம்',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'திதி · நட்சத்திரம் · நல்ல நேரம்',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(color: AppColors.goldLight),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: AppColors.goldLight,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _navIndex == 2 ? Colors.white : AppColors.cream,
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: AppColors.gold.withValues(alpha: 0.28)),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.maroon.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: NavigationBarTheme(
            data: NavigationBarThemeData(
              height: 64,
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              indicatorColor: AppColors.maroon.withValues(alpha: 0.1),
              labelPadding: const EdgeInsets.only(top: 0, bottom: 2),
              iconTheme: WidgetStateProperty.resolveWith((states) {
                final selected = states.contains(WidgetState.selected);
                return IconThemeData(
                  size: 22,
                  color: selected
                      ? AppColors.maroon
                      : AppColors.textSecondary.withValues(alpha: 0.75),
                );
              }),
              labelTextStyle: WidgetStateProperty.resolveWith((states) {
                final selected = states.contains(WidgetState.selected);
                return TextStyle(
                  fontSize: 9.5,
                  height: 1.0,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected
                      ? AppColors.maroon
                      : AppColors.textSecondary.withValues(alpha: 0.85),
                );
              }),
            ),
            child: NavigationBar(
              selectedIndex: _navIndex,
              onDestinationSelected: (index) =>
                  setState(() => _navIndex = index),
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              animationDuration: const Duration(milliseconds: 280),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home_rounded),
                  label: 'முகப்பு',
                ),
                NavigationDestination(
                  icon: Icon(Icons.temple_hindu_outlined),
                  selectedIcon: Icon(Icons.temple_hindu_rounded),
                  label: 'ஆன்மீகம்',
                ),
                NavigationDestination(
                  icon: Icon(Icons.menu_book_outlined),
                  selectedIcon: Icon(Icons.menu_book_rounded),
                  label: 'நூலகம்',
                ),
                NavigationDestination(
                  icon: Icon(Icons.account_balance_wallet_outlined),
                  selectedIcon: Icon(Icons.account_balance_wallet_rounded),
                  label: 'செலவு',
                ),
                NavigationDestination(
                  icon: Icon(Icons.today_outlined),
                  selectedIcon: Icon(Icons.today_rounded),
                  label: 'இன்று',
                ),
              ],
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _ErrorView(
              error: _error!,
              onRetry: _load,
              usesBundled: widget.repository.usesBundledCalendar,
            )
          : RefreshIndicator(
              onRefresh: () async {
                await Future.wait([
                  _load(),
                  _loadStatusStories(),
                  _loadIndru(),
                  _loadKoodiyaThagaval(),
                ]);
              },
              color: AppColors.maroon,
              child: CustomScrollView(
                slivers: [
                  SliverAppBar(
                    expandedHeight: 88,
                    floating: false,
                    pinned: true,
                    stretch: true,
                    automaticallyImplyLeading: false,
                    leadingWidth: 0,
                    backgroundColor: AppColors.maroonDark,
                    foregroundColor: Colors.white,
                    centerTitle: false,
                    titleSpacing: 0,
                    flexibleSpace: FlexibleSpaceBar(
                      expandedTitleScale: 1,
                      titlePadding: const EdgeInsets.only(
                        left: 16,
                        bottom: 12,
                        right: 16,
                      ),
                      title: _HomeHeaderTitle(greeting: _greeting()),
                      background: Container(
                        decoration: const BoxDecoration(
                          gradient: AppDecorations.headerGradient,
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              right: -30,
                              top: -20,
                              child: Opacity(
                                opacity: 0.08,
                                child: Image.asset(
                                  'assets/images/icon_panchangam.webp',
                                  width: 140,
                                  height: 140,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                      child: _buildTabContent(),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _HomeHeaderTitle extends StatelessWidget {
  const _HomeHeaderTitle({required this.greeting});

  final String greeting;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          greeting,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.goldLight.withValues(alpha: 0.95),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Murugan தமிழ் Calendar',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
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
    final monthYear = parts.length >= 3
        ? '${parts[1]}-${parts[2]}'
        : home.gregorianDisplay;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          decoration: BoxDecoration(
            gradient: AppDecorations.heroGradient,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: AppColors.gold.withValues(alpha: 0.35),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.maroon.withValues(alpha: 0.35),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: KolamPattern(
            opacity: 0.14,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.goldLight.withValues(alpha: 0.45),
                          ),
                        ),
                        child: Text(
                          home.bannerLineTa,
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: AppColors.goldLight,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: MenuIcon(
                            kind: MenuIconKind.panchangam,
                            size: 20,
                            color: AppColors.goldLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        dayNum,
                        style: Theme.of(context).textTheme.displayLarge
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              height: 1,
                              fontSize: 80,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14, left: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              monthYear,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: AppColors.goldLight,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            if (today != null)
                              Text(
                                today!.subtitleLine2Ta,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: Colors.white70),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (today != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        today!.subtitleLine1Ta,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.92),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.touch_app_rounded,
                          color: AppColors.goldLight,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'முழு விவரம் பார்க்க',
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: AppColors.goldLight,
                                fontWeight: FontWeight.w600,
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
      ),
    );
  }
}

// ─────────────────────────────────────────
// Raasi Palan home card – below hero date card
// ─────────────────────────────────────────
class _RaasiPalanHomeCard extends StatelessWidget {
  const _RaasiPalanHomeCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2D0061), Color(0xFF4A148C), Color(0xFF6A1B9A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4A148C).withValues(alpha: 0.45),
                blurRadius: 20,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title row
                Row(
                  children: [
                    // Leo artwork as card icon
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: ZodiacSignIcon(
                        index: 4, // Leo (சிம்மம்)
                        size: 46,
                        borderRadius: 10,
                        showGoldenBg: true,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ராசி பலன்கள்',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.4,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'இன்று · வாரம் · மாதம் · ஆண்டு',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.white,
                        size: 20,
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

class _TempleHeroButton extends StatelessWidget {
  const _TempleHeroButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2E1A47), Color(0xFF5B2E91)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2E1A47).withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/images/icon_temple.webp',
                    width: 62,
                    height: 62,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'பிரபல கோவில்கள்',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'படங்களுடன் ஆன்மிக யாத்திரை வழிகாட்டி',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.goldLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: AppColors.goldLight,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IndruSectionCard extends StatelessWidget {
  const _IndruSectionCard({
    required this.emoji,
    required this.title,
    required this.body,
    this.detail = '',
    this.italicBody = false,
  });

  final String emoji;
  final String title;
  final String body;
  final String detail;
  final bool italicBody;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.maroon,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              height: 1.5,
              fontStyle: italicBody ? FontStyle.italic : FontStyle.normal,
              color: AppColors.textPrimary,
            ),
          ),
          if (detail.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              detail,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                height: 1.45,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.error,
    required this.onRetry,
    required this.usesBundled,
  });

  final String error;
  final VoidCallback onRetry;
  final bool usesBundled;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: AppCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_off_rounded,
                size: 48,
                color: AppColors.maroon.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 16),
              Text(
                usesBundled ? 'தரவு இல்லை' : 'இணைப்பு தோல்வி',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                error,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              Text(
                usesBundled
                    ? 'ஆஃப்லைன்: 2026 தமிழ் காலண்டர் தரவு மட்டும் (365 நாட்கள்).'
                    : 'இணையம் தேவை — அல்லது ஆஃப்லைன் தமிழ் காலண்டர் தரவை பயன்படுத்துங்கள்.',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('மீண்டும் முயற்சி'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.maroon,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
