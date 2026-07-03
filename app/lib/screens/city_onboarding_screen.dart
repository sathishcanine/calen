import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/tamil_nadu_city_ids.dart';
import '../models/city.dart';
import '../services/calendar_repository.dart';
import '../services/city_preferences_service.dart';
import '../theme/app_theme.dart';
import '../widgets/kolam_pattern.dart';

enum _CityFilter { all, tamilNadu, india, abroad }

/// Onboarding / change-city screen — bilingual labels: Chennai - சென்னை
class CityOnboardingScreen extends StatefulWidget {
  const CityOnboardingScreen({
    super.key,
    required this.repository,
    required this.onComplete,
    this.changeMode = false,
  });

  final CalendarRepository repository;
  final VoidCallback onComplete;
  final bool changeMode;

  @override
  State<CityOnboardingScreen> createState() => _CityOnboardingScreenState();
}

class _CityOnboardingScreenState extends State<CityOnboardingScreen>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();

  List<City> _allCities = [];
  City? _selected;
  _CityFilter _filter = _CityFilter.all;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  late final AnimationController _pulseController;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _selected = CityPreferencesService.instance.selectedCity;
    _loadCities();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadCities() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final cities = await widget.repository.getCities();
      cities.sort((a, b) => a.nameEn.compareTo(b.nameEn));
      if (mounted) setState(() => _allCities = cities);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<City> get _filtered {
    final q = _searchController.text;
    return _allCities.where((city) {
      if (!city.matchesQuery(q)) return false;
      return switch (_filter) {
        _CityFilter.all => true,
        _CityFilter.tamilNadu => tamilNaduCityIds.contains(city.id),
        _CityFilter.india => city.country == 'IN',
        _CityFilter.abroad => city.country != 'IN',
      };
    }).toList();
  }

  List<City> get _featured {
    final byId = {for (final c in _allCities) c.id: c};
    return featuredCityIds
        .map((id) => byId[id])
        .whereType<City>()
        .where((c) => c.matchesQuery(_searchController.text))
        .toList();
  }

  Future<void> _confirm() async {
    final city = _selected;
    if (city == null) return;

    setState(() => _saving = true);
    HapticFeedback.mediumImpact();
    try {
      await CityPreferencesService.instance.setCity(city);
      if (!mounted) return;
      widget.onComplete();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: KolamPattern(
        opacity: 0.05,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(
                changeMode: widget.changeMode,
                pulse: _pulse,
                onBack: widget.changeMode ? () => Navigator.pop(context) : null,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: _SearchField(
                  controller: _searchController,
                  focusNode: _searchFocus,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _FilterChips(
                  selected: _filter,
                  onSelected: (f) => setState(() => _filter = f),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? _ErrorPane(message: _error!, onRetry: _loadCities)
                        : _CityList(
                            featured: _featured,
                            cities: _filtered,
                            selected: _selected,
                            showFeatured: _searchController.text.isEmpty &&
                                _filter == _CityFilter.all,
                            onSelect: (c) {
                              HapticFeedback.selectionClick();
                              setState(() => _selected = c);
                            },
                          ),
              ),
              _BottomBar(
                selected: _selected,
                saving: _saving,
                changeMode: widget.changeMode,
                onConfirm: _confirm,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.changeMode,
    required this.pulse,
    this.onBack,
  });

  final bool changeMode;
  final Animation<double> pulse;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        gradient: AppDecorations.headerGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.maroon.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -24,
            top: -24,
            child: ScaleTransition(
              scale: pulse,
              child: Icon(
                Icons.temple_hindu_rounded,
                size: 120,
                color: Colors.white.withValues(alpha: 0.07),
              ),
            ),
          ),
          Positioned(
            left: -16,
            bottom: -20,
            child: Icon(
              Icons.location_on_rounded,
              size: 80,
              color: AppColors.gold.withValues(alpha: 0.12),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (onBack != null)
                  IconButton(
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                if (onBack != null) const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.gold.withValues(alpha: 0.45),
                        ),
                      ),
                      child: const Icon(
                        Icons.public_rounded,
                        color: AppColors.goldLight,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            changeMode ? 'ஊர் மாற்றம்' : 'வணக்கம்!',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  height: 1.1,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            changeMode
                                ? 'புதிய ஊரைத் தேர்வு செய்யுங்கள்'
                                : 'உங்கள் ஊரைத் தேர்வு செய்யுங்கள்',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.88),
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 16,
                        color: AppColors.goldLight.withValues(alpha: 0.9),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'நல்ல நேரம், ராகு காலம் — உங்கள் ஊரின் நேரப்படி',
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                        ),
                      ),
                    ],
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

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.focusNode});

  final TextEditingController controller;
  final FocusNode focusNode;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppDecorations.goldBorder(),
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, value, _) {
          return TextField(
            controller: controller,
            focusNode: focusNode,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Chennai / சென்னை / Madurai …',
              hintStyle: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.7)),
              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.maroon),
              suffixIcon: value.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () => controller.clear(),
                      icon: const Icon(Icons.close_rounded, size: 20),
                    ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          );
        },
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.selected, required this.onSelected});

  final _CityFilter selected;
  final ValueChanged<_CityFilter> onSelected;

  static const _labels = {
    _CityFilter.all: 'அனைத்தும்',
    _CityFilter.tamilNadu: 'தமிழ்நாடு',
    _CityFilter.india: 'இந்தியா',
    _CityFilter.abroad: 'வெளிநாடு',
  };

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _CityFilter.values.map((f) {
          final isOn = f == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(_labels[f]!),
              selected: isOn,
              onSelected: (_) => onSelected(f),
              showCheckmark: false,
              selectedColor: AppColors.maroon.withValues(alpha: 0.12),
              backgroundColor: AppColors.surface,
              side: BorderSide(
                color: isOn ? AppColors.maroon : AppColors.creamDark,
                width: isOn ? 1.5 : 1,
              ),
              labelStyle: TextStyle(
                color: isOn ? AppColors.maroon : AppColors.textSecondary,
                fontWeight: isOn ? FontWeight.w700 : FontWeight.w500,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _CityList extends StatelessWidget {
  const _CityList({
    required this.featured,
    required this.cities,
    required this.selected,
    required this.showFeatured,
    required this.onSelect,
  });

  final List<City> featured;
  final List<City> cities;
  final City? selected;
  final bool showFeatured;
  final ValueChanged<City> onSelect;

  @override
  Widget build(BuildContext context) {
    if (cities.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_off_rounded, size: 48, color: AppColors.textSecondary.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text(
              'ஊர் கிடைக்கவில்லை',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      children: [
        if (showFeatured && featured.isNotEmpty) ...[
          _SectionLabel(title: 'பிரபலமான ஊர்கள்'),
          SizedBox(
            height: 118,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: featured.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final city = featured[i];
                final isSelected = selected?.id == city.id;
                return _FeaturedCityCard(
                  city: city,
                  selected: isSelected,
                  onTap: () => onSelect(city),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          _SectionLabel(title: 'அனைத்து ஊர்கள்'),
        ],
        ...cities.map(
          (city) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _CityTile(
              city: city,
              selected: selected?.id == city.id,
              onTap: () => onSelect(city),
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppColors.maroon,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

class _FeaturedCityCard extends StatelessWidget {
  const _FeaturedCityCard({
    required this.city,
    required this.selected,
    required this.onTap,
  });

  final City city;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        width: 132,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: selected
              ? LinearGradient(
                  colors: [
                    AppColors.maroon.withValues(alpha: 0.08),
                    AppColors.goldLight.withValues(alpha: 0.2),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: selected ? null : AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? AppColors.gold : AppColors.creamDark,
            width: selected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.maroon.withValues(alpha: selected ? 0.12 : 0.05),
              blurRadius: selected ? 14 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.place_rounded,
                  size: 18,
                  color: selected ? AppColors.maroon : AppColors.textSecondary,
                ),
                const Spacer(),
                if (selected)
                  const Icon(Icons.check_circle_rounded, color: AppColors.maroon, size: 18),
              ],
            ),
            const Spacer(),
            Text(
              city.nameEn,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              city.nameTa,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CityTile extends StatelessWidget {
  const _CityTile({
    required this.city,
    required this.selected,
    required this.onTap,
  });

  final City city;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: selected ? AppColors.maroon.withValues(alpha: 0.06) : AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? AppColors.maroon : AppColors.creamDark,
              width: selected ? 2 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.maroon.withValues(alpha: 0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: selected
                      ? AppDecorations.headerGradient
                      : LinearGradient(
                          colors: [
                            AppColors.creamDark,
                            AppColors.creamDark.withValues(alpha: 0.6),
                          ],
                        ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.location_city_rounded,
                  color: selected ? Colors.white : AppColors.maroon,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      city.displayName,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            height: 1.25,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _regionLabel(city),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: selected
                    ? const Icon(
                        Icons.check_circle_rounded,
                        key: ValueKey('on'),
                        color: AppColors.maroon,
                        size: 26,
                      )
                    : Icon(
                        Icons.circle_outlined,
                        key: const ValueKey('off'),
                        color: AppColors.textSecondary.withValues(alpha: 0.35),
                        size: 26,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _regionLabel(City city) {
    if (tamilNaduCityIds.contains(city.id)) return 'தமிழ்நாடு';
    if (city.country == 'IN') return 'இந்தியா';
    if (city.country == 'LK') return 'இலங்கை';
    if (city.country == 'SG') return 'சிங்கப்பூர்';
    if (city.country == 'MY') return 'மலேசியா';
    if (city.country == 'AE') return 'ஐக்கிய அரபு எமிரேட்ஸ்';
    if (city.country == 'US') return 'அமெரிக்கா';
    if (city.country == 'GB') return 'இங்கிலாந்து';
    if (city.country == 'CA') return 'கனடா';
    if (city.country == 'AU') return 'ஆஸ்திரேலியா';
    return city.country;
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.selected,
    required this.saving,
    required this.changeMode,
    required this.onConfirm,
  });

  final City? selected;
  final bool saving;
  final bool changeMode;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final enabled = selected != null && !saving;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.maroon.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (selected != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  const Icon(Icons.pin_drop_rounded, color: AppColors.maroon, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      selected!.displayName,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: enabled
                    ? AppDecorations.headerGradient
                    : LinearGradient(
                        colors: [
                          AppColors.creamDark,
                          AppColors.creamDark.withValues(alpha: 0.8),
                        ],
                      ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: enabled
                    ? [
                        BoxShadow(
                          color: AppColors.maroon.withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : null,
              ),
              child: ElevatedButton(
                onPressed: enabled ? onConfirm : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  disabledForegroundColor: AppColors.textSecondary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        changeMode ? 'சேமிக்கவும்' : 'தொடரவும்',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorPane extends StatelessWidget {
  const _ErrorPane({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.maroon),
            const SizedBox(height: 12),
            Text(
              'ஊர்கள் ஏற்றுவது தோல்வி',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('மீண்டும்'),
            ),
          ],
        ),
      ),
    );
  }
}
