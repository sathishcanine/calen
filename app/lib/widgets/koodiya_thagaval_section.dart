import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/koodiya_thagaval_post.dart';
import '../models/post.dart';
import '../screens/post_detail_screen.dart';
import '../services/calendar_repository.dart';
import '../theme/app_theme.dart';

/// Supplementary தகவல் cards shown below இன்று daily content.
class KoodiyaThagavalSection extends StatelessWidget {
  const KoodiyaThagavalSection({
    super.key,
    required this.repository,
    required this.posts,
    required this.loading,
  });

  final CalendarRepository repository;
  final List<KoodiyaThagavalPost> posts;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (posts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        ...posts.asMap().entries.map((entry) {
          final index = entry.key;
          final post = entry.value;
          return Padding(
            padding: EdgeInsets.only(bottom: index < posts.length - 1 ? 14 : 0),
            child: _ThagavalCard(
              post: post,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => PostDetailScreen(
                    repository: repository,
                    postId: post.id,
                    initialPost: _toPost(post),
                  ),
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 4),
      ],
    );
  }
}

class _ThagavalCard extends StatelessWidget {
  const _ThagavalCard({required this.post, required this.onTap});

  final KoodiyaThagavalPost post;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateLabel = post.createdAt != null
        ? DateFormat('d MMM yyyy').format(post.createdAt!.toLocal())
        : '';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDecorations.cardRadius),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDecorations.cardRadius),
            border: Border.all(
              color: AppColors.gold.withValues(alpha: 0.35),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.maroon.withValues(alpha: 0.08),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppDecorations.cardRadius - 1),
                ),
                child: Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Image.network(
                        post.imageUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (_, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            color: AppColors.creamDark,
                            alignment: Alignment.center,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          );
                        },
                        errorBuilder: (_, _, _) => Container(
                          color: AppColors.cream,
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            color: AppColors.textSecondary.withValues(alpha: 0.5),
                            size: 40,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.72),
                            ],
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(14, 28, 14, 12),
                          child: Text(
                            post.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              height: 1.25,
                              shadows: const [
                                Shadow(
                                  color: Colors.black45,
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (post.preview.isNotEmpty)
                      Text(
                        post.preview,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.45,
                        ),
                      ),
                    if (dateLabel.isNotEmpty) ...[
                      if (post.preview.isNotEmpty) const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            size: 14,
                            color: AppColors.maroon.withValues(alpha: 0.7),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            dateLabel,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppColors.maroon.withValues(alpha: 0.75),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'மேலும் படிக்க',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppColors.goldDark,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 11,
                            color: AppColors.goldDark,
                          ),
                        ],
                      ),
                    ],
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

Post _toPost(KoodiyaThagavalPost item) => Post(
      id: item.id,
      title: item.title,
      content: item.content,
      imageUrl: item.imageUrl,
      pushSent: item.pushSent,
      createdAt: item.createdAt,
      blocks: item.blocks,
    );
