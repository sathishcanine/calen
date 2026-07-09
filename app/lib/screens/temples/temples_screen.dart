import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'dart:math';

import '../../config/ad_config.dart';
import '../../models/temple.dart';
import '../../services/calendar_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/native_ad_widget.dart';

class TemplesScreen extends StatefulWidget {
  const TemplesScreen({super.key, required this.repository});

  final CalendarRepository repository;

  @override
  State<TemplesScreen> createState() => _TemplesScreenState();
}

class _TemplesScreenState extends State<TemplesScreen> {
  static const int _pageSize = 12;

  final ScrollController _scrollController = ScrollController();
  final List<Temple> _items = <Temple>[];

  final Set<String> _deityOptions = <String>{};
  final Set<String> _regionOptions = <String>{};
  final Set<String> _selectedDeities = <String>{};
  final Set<String> _selectedRegions = <String>{};

  bool _hasCustomDeitySelection = false;
  bool _hasCustomRegionSelection = false;
  bool _isInitialLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _error;
  late final int _heroSeed;

  @override
  void initState() {
    super.initState();
    _heroSeed = Random().nextInt(1 << 31);
    _scrollController.addListener(_onScroll);
    _loadNextPage(initial: true);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  Future<void> _loadNextPage({bool initial = false}) async {
    if (_isLoadingMore || (!_hasMore && !initial)) return;

    if (initial) {
      setState(() {
        _isInitialLoading = true;
        _error = null;
        _hasMore = true;
        _items.clear();
      });
    } else {
      setState(() => _isLoadingMore = true);
    }

    List<Temple> rows;
    try {
      rows = await widget.repository.getTemples(
        limit: _pageSize,
        offset: _items.length,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isInitialLoading = false;
        _isLoadingMore = false;
        _hasMore = false;
        _error = 'கோவில் தகவல் ஏற்ற முடியவில்லை. மீண்டும் முயற்சிக்கவும்.';
      });
      return;
    }

    if (!mounted) return;

    if (initial && rows.isEmpty) {
      setState(() {
        _isInitialLoading = false;
        _isLoadingMore = false;
        _hasMore = false;
        _error = 'கோவில் தகவல் தற்போது இல்லை. பின்னர் முயற்சிக்கவும்.';
      });
      return;
    }

    setState(() {
      _items.addAll(rows);
      _hasMore = rows.length == _pageSize;
      _isInitialLoading = false;
      _isLoadingMore = false;
      _error = null;
    });

    _refreshFilterOptions(rows);
  }

  void _refreshFilterOptions(List<Temple> rows) {
    var changed = false;
    for (final temple in rows) {
      final deity = _deityCategoryFor(temple);
      final region = _regionFor(temple);

      if (_deityOptions.add(deity)) {
        changed = true;
        if (!_hasCustomDeitySelection) _selectedDeities.add(deity);
      }
      if (_regionOptions.add(region)) {
        changed = true;
        if (!_hasCustomRegionSelection) _selectedRegions.add(region);
      }
    }
    if (changed && mounted) setState(() {});
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _isLoadingMore || !_hasMore) return;
    final remaining =
        _scrollController.position.maxScrollExtent - _scrollController.offset;
    if (remaining < 350) {
      _loadNextPage();
    }
  }

  String _deityCategoryFor(Temple temple) {
    final text = '${temple.nameTa} ${temple.deityTa}'.toLowerCase();
    if (text.contains('முருக') || text.contains('சுப்பிரமணிய')) {
      return 'முருகன்';
    }
    if (text.contains('பெருமாள்') ||
        text.contains('நாராயண') ||
        text.contains('விஷ்ணு')) {
      return 'பெருமாள்';
    }
    if (text.contains('அம்மன்') ||
        text.contains('மாரியம்மன்') ||
        text.contains('துர்க்கை')) {
      return 'அம்மன்';
    }
    if (text.contains('விநாய') ||
        text.contains('பிள்ளையார்') ||
        text.contains('கணபதி')) {
      return 'விநாயகர்';
    }
    return 'சிவன்';
  }

  String _regionFor(Temple temple) {
    final value = temple.locationTa.trim();
    final head = value.split('(').first.trim();
    return head.isEmpty ? 'மற்றவை' : head;
  }

  List<Temple> get _filtered {
    return _items.where((t) {
      final deity = _deityCategoryFor(t);
      final region = _regionFor(t);
      return _selectedDeities.contains(deity) &&
          _selectedRegions.contains(region);
    }).toList();
  }

  Future<void> _showFilterSheet({
    required String title,
    required Set<String> options,
    required Set<String> selected,
    required void Function(Set<String> next) onApply,
  }) async {
    final picked = await showModalBottomSheet<Set<String>>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        final temp = Set<String>.from(selected);
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.72,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Builder(
                                builder: (context) {
                                  final allSelected =
                                      temp.length == options.length;
                                  return Text(
                                    allSelected ? 'Deselect all' : 'Select all',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: AppColors.textSecondary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  );
                                },
                              ),
                              const SizedBox(width: 4),
                              Checkbox(
                                tristate: true,
                                value: temp.isEmpty
                                    ? false
                                    : (temp.length == options.length
                                          ? true
                                          : null),
                                onChanged: (_) {
                                  setModalState(() {
                                    if (temp.length == options.length) {
                                      temp.clear();
                                    } else {
                                      temp
                                        ..clear()
                                        ..addAll(options);
                                    }
                                  });
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView(
                        children: options
                            .map(
                              (item) => CheckboxListTile(
                                value: temp.contains(item),
                                title: Text(item),
                                onChanged: (checked) {
                                  setModalState(() {
                                    if (checked == true) {
                                      temp.add(item);
                                    } else {
                                      temp.remove(item);
                                    }
                                  });
                                },
                              ),
                            )
                            .toList(),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () => Navigator.pop(context, temp),
                          child: const Text('Apply'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (picked == null || !mounted) return;
    onApply(picked);
  }

  @override
  Widget build(BuildContext context) {
    final temples = _filtered;
    final featured = temples.isNotEmpty
        ? temples[_heroSeed % temples.length]
        : null;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('பிரபல கோவில்கள்')),
      body: RefreshIndicator(
        onRefresh: () => _loadNextPage(initial: true),
        child: _isInitialLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              )
            : ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 20),
                itemCount: temples.length + 4,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _TempleFilterBar(
                        selectedDeities: _selectedDeities.length,
                        totalDeities: _deityOptions.length,
                        selectedRegions: _selectedRegions.length,
                        totalRegions: _regionOptions.length,
                        onDeityTap: () => _showFilterSheet(
                          title: 'தெய்வ வகை',
                          options: _deityOptions,
                          selected: _selectedDeities,
                          onApply: (next) => setState(() {
                            _hasCustomDeitySelection = true;
                            _selectedDeities
                              ..clear()
                              ..addAll(next);
                          }),
                        ),
                        onRegionTap: () => _showFilterSheet(
                          title: 'பகுதி',
                          options: _regionOptions,
                          selected: _selectedRegions,
                          onApply: (next) => setState(() {
                            _hasCustomRegionSelection = true;
                            _selectedRegions
                              ..clear()
                              ..addAll(next);
                          }),
                        ),
                      ),
                    );
                  }

                  if (index == 1 && featured != null) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _HeroTempleCard(temple: featured),
                    );
                  }

                  if (index == 2) {
                    if (temples.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(8, 20, 8, 8),
                        child: Text(
                          'இந்த filter-க்கு பொருந்தும் கோவில்கள் இல்லை.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      );
                    }
                    return const SizedBox(height: 2);
                  }

                  if (temples.isEmpty) {
                    if (_isLoadingMore) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    return const SizedBox.shrink();
                  }

                  final templeIndex = index - 3;
                  if (templeIndex >= 0 && templeIndex < temples.length) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _TempleListCard(temple: temples[templeIndex]),
                    );
                  }

                  if (_isLoadingMore) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (!_hasMore) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(child: Text('முடிந்தது')),
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
      ),
    );
  }
}

class _TempleFilterBar extends StatelessWidget {
  const _TempleFilterBar({
    required this.selectedDeities,
    required this.totalDeities,
    required this.selectedRegions,
    required this.totalRegions,
    required this.onDeityTap,
    required this.onRegionTap,
  });

  final int selectedDeities;
  final int totalDeities;
  final int selectedRegions;
  final int totalRegions;
  final VoidCallback onDeityTap;
  final VoidCallback onRegionTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.28)),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          OutlinedButton.icon(
            onPressed: onDeityTap,
            icon: const Icon(Icons.temple_hindu_rounded, size: 18),
            label: Text('தெய்வம் ($selectedDeities/$totalDeities)'),
          ),
          OutlinedButton.icon(
            onPressed: onRegionTap,
            icon: const Icon(Icons.location_on_rounded, size: 18),
            label: Text('பகுதி ($selectedRegions/$totalRegions)'),
          ),
        ],
      ),
    );
  }
}

class _HeroTempleCard extends StatelessWidget {
  const _HeroTempleCard({required this.temple});

  final Temple temple;

  @override
  Widget build(BuildContext context) {
    return _TempleCoverCard(temple: temple, showFeaturedBadge: true);
  }
}

class _TempleListCard extends StatelessWidget {
  const _TempleListCard({required this.temple});

  final Temple temple;

  @override
  Widget build(BuildContext context) {
    return _TempleCoverCard(temple: temple);
  }
}

class _TempleCoverCard extends StatelessWidget {
  const _TempleCoverCard({
    required this.temple,
    this.showFeaturedBadge = false,
  });

  final Temple temple;
  final bool showFeaturedBadge;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TempleDetailScreen(temple: temple)),
        ),
        child: Ink(
          height: 210,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: Colors.black12,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl: temple.imageUrl,
                  fit: BoxFit.cover,
                  fadeInDuration: Duration.zero,
                  fadeOutDuration: Duration.zero,
                  placeholderFadeInDuration: Duration.zero,
                  errorWidget: (_, _, _) =>
                      Container(color: AppColors.maroonDark),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.06),
                        Colors.black.withValues(alpha: 0.65),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 14,
                  right: 14,
                  bottom: 14,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (showFeaturedBadge) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.gold.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'சிறப்பு பரிந்துரை',
                            style: TextStyle(
                              color: AppColors.maroonDark,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      Text(
                        temple.nameTa,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        temple.locationTa,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
    );
  }
}

class TempleDetailLoaderScreen extends StatelessWidget {
  const TempleDetailLoaderScreen({
    super.key,
    required this.repository,
    required this.slug,
  });

  final CalendarRepository repository;
  final String slug;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Temple?>(
      future: repository.getTempleBySlug(slug),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppColors.cream,
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final temple = snapshot.data;
        if (temple == null) {
          return Scaffold(
            backgroundColor: AppColors.cream,
            appBar: AppBar(title: const Text('கோவில் விவரம்')),
            body: const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'கோவில் தகவல் ஏற்ற முடியவில்லை.\nஇணைய இணைப்பைச் சரிபார்த்து மீண்டும் முயற்சிக்கவும்.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }
        return TempleDetailScreen(temple: temple);
      },
    );
  }
}

class TempleDetailScreen extends StatelessWidget {
  const TempleDetailScreen({super.key, required this.temple});

  final Temple temple;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: AppColors.maroonDark,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsetsDirectional.only(
                start: 16,
                bottom: 12,
                end: 16,
              ),
              title: Text(
                temple.nameTa,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: temple.imageUrl,
                    fit: BoxFit.cover,
                    fadeInDuration: Duration.zero,
                    fadeOutDuration: Duration.zero,
                    placeholderFadeInDuration: Duration.zero,
                    errorWidget: (_, _, _) =>
                        Container(color: AppColors.maroonDark),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.1),
                          Colors.black.withValues(alpha: 0.65),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.maroonDark,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      temple.nameEn,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _InfoChip(
                    icon: Icons.location_on_rounded,
                    label: temple.locationTa,
                  ),
                  const SizedBox(height: 8),
                  _InfoChip(
                    icon: Icons.auto_awesome_rounded,
                    label: temple.deityTa,
                  ),
                  const SizedBox(height: 16),
                  NativeAdWidget(adUnitId: AdConfig.templeNativeUnitId),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.24),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.menu_book_rounded,
                              size: 18,
                              color: AppColors.maroon,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'கோவில் விவரம்',
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    color: AppColors.maroon,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ..._descriptionChunks(temple.descriptionTa).map(
                          (line) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(top: 8),
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: AppColors.maroon,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    line,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          height: 1.6,
                                          color: AppColors.textPrimary,
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
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.maroon.withValues(alpha: 0.16),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.verified_rounded,
                          color: AppColors.maroon,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'தகவல் மூலம்: ${temple.sourceLabel}\n${temple.sourceUrl}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: AppColors.textSecondary,
                                  height: 1.4,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.24)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.maroon),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

List<String> _descriptionChunks(String text) {
  final cleaned = text.replaceAll('\n', ' ').trim();
  if (cleaned.isEmpty) return const [];
  final normalized = cleaned.replaceAll('।', '.').replaceAll('..', '.');
  final parts = normalized
      .split('.')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();
  if (parts.isEmpty) return [cleaned];
  return parts
      .map((e) => e.endsWith('?') || e.endsWith('!') ? e : '$e.')
      .toList();
}
