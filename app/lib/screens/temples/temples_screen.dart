import 'package:flutter/material.dart';

import '../../models/temple.dart';
import '../../services/calendar_repository.dart';
import '../../theme/app_theme.dart';

class TemplesScreen extends StatefulWidget {
  const TemplesScreen({super.key, required this.repository});

  final CalendarRepository repository;

  @override
  State<TemplesScreen> createState() => _TemplesScreenState();
}

class _TemplesScreenState extends State<TemplesScreen> {
  late final Future<List<Temple>> _templesFuture;

  @override
  void initState() {
    super.initState();
    _templesFuture = widget.repository.getTemples(limit: 60);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('பிரபல கோவில்கள்')),
      body: FutureBuilder<List<Temple>>(
        future: _templesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final temples = snapshot.data ?? const <Temple>[];
          if (temples.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'கோவில் தகவல் தற்போது இல்லை.\nசர்வர் இயக்கத்தில் இருந்தால் சில நொடிகளில் மீண்டும் முயற்சிக்கவும்.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                ),
              ),
            );
          }

          final featured = temples.firstWhere(
            (e) => e.isFeatured,
            orElse: () => temples.first,
          );

          return ListView(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 20),
            children: [
              _HeroTempleCard(temple: featured),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.gold.withValues(alpha: 0.28)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: AppColors.maroon),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                                '${temples.length} கோவில் பதிவுகள் • ${featured.sourceLabel} ஆதாரத்திலிருந்து புதுப்பிப்பு',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              ...temples.map(
                (temple) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _TempleListCard(temple: temple),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HeroTempleCard extends StatelessWidget {
  const _HeroTempleCard({required this.temple});

  final Temple temple;

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
                Image.network(
                  temple.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(color: AppColors.maroonDark),
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
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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

class _TempleListCard extends StatelessWidget {
  const _TempleListCard({required this.temple});

  final Temple temple;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TempleDetailScreen(temple: temple)),
        ),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.gold.withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(
                color: AppColors.maroon.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: SizedBox(
                  height: 160,
                  width: double.infinity,
                  child: Image.network(
                    temple.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      color: AppColors.creamDark,
                      alignment: Alignment.center,
                      child: const Icon(Icons.temple_hindu_rounded, size: 40, color: AppColors.maroon),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      temple.nameTa,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.maroon,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      temple.nameEn,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded, size: 16, color: AppColors.maroon),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            temple.locationTa,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      temple.descriptionTa,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
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
              titlePadding: const EdgeInsetsDirectional.only(start: 16, bottom: 12, end: 16),
              title: Text(
                temple.nameTa,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    temple.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(color: AppColors.maroonDark),
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
                  Text(
                    temple.nameEn,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.maroon,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 10),
                  _InfoChip(icon: Icons.location_on_rounded, label: temple.locationTa),
                  const SizedBox(height: 8),
                  _InfoChip(icon: Icons.auto_awesome_rounded, label: temple.deityTa),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.gold.withValues(alpha: 0.24)),
                    ),
                    child: Text(
                      temple.descriptionTa,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            height: 1.55,
                            color: AppColors.textPrimary,
                          ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.maroon.withValues(alpha: 0.16)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.verified_rounded, color: AppColors.maroon),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'தகவல் மூலம்: ${temple.sourceLabel}\n${temple.sourceUrl}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
