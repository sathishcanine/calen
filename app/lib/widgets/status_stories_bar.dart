import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/status_story.dart';
import '../theme/app_theme.dart';
import 'status_story_viewer_screen.dart';

const _ringSize = 76.0;
const _innerSize = 66.0;
const _borderWidth = 3.0;
const _seenBorderColor = Color(0xFFBDBDBD);
const _unseenBorderColor = Color(0xFFC2185B);
const _headerColor = Color(0xFF1A237E);

/// Slow rotating ring skeleton while status stories load from the API.
class StatusStoriesBarSkeleton extends StatefulWidget {
  const StatusStoriesBarSkeleton({super.key, this.itemCount = 5});

  final int itemCount;

  @override
  State<StatusStoriesBarSkeleton> createState() => _StatusStoriesBarSkeletonState();
}

class _StatusStoriesBarSkeletonState extends State<StatusStoriesBarSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Daily Status',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: _headerColor,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: _ringSize,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.itemCount,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, __) => _LoadingStoryRing(animation: _spin),
          ),
        ),
      ],
    );
  }
}

class _LoadingStoryRing extends StatelessWidget {
  const _LoadingStoryRing({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _ringSize,
      height: _ringSize,
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, _) {
          return CustomPaint(
            painter: _AnimatedRingPainter(
              rotation: animation.value * 2 * math.pi,
              borderWidth: _borderWidth,
              colors: const [
                _unseenBorderColor,
                Color(0xFFAD1457),
                Color(0xFFE1BEE7),
                Color(0xFF7B1FA2),
                _unseenBorderColor,
              ],
            ),
            child: Center(
              child: Container(
                width: _innerSize,
                height: _innerSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.creamDark,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Daily Status row — circular thumbnails with seen/unseen rings.
class StatusStoriesBar extends StatelessWidget {
  const StatusStoriesBar({
    super.key,
    required this.stories,
    required this.viewedIds,
    required this.onViewed,
  });

  final List<StatusStory> stories;
  final Set<String> viewedIds;
  final VoidCallback onViewed;

  @override
  Widget build(BuildContext context) {
    if (stories.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Daily Status',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: _headerColor,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: _ringSize,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: stories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final story = stories[index];
              final seen = viewedIds.contains(story.id);
              return _StoryBubble(
                story: story,
                seen: seen,
                onTap: () async {
                  await Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder: (_) => StatusStoryViewerScreen(
                        stories: stories,
                        initialIndex: index,
                        viewedIds: viewedIds,
                      ),
                    ),
                  );
                  onViewed();
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _StoryBubble extends StatelessWidget {
  const _StoryBubble({
    required this.story,
    required this.seen,
    required this.onTap,
  });

  final StatusStory story;
  final bool seen;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: _ringSize,
        height: _ringSize,
        child: Container(
          padding: const EdgeInsets.all(_borderWidth),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: seen ? _seenBorderColor : _unseenBorderColor,
              width: seen ? 2 : _borderWidth,
            ),
          ),
          child: Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            clipBehavior: Clip.antiAlias,
            child: _StoryThumb(story: story),
          ),
        ),
      ),
    );
  }
}

class _StoryThumb extends StatelessWidget {
  const _StoryThumb({required this.story});

  final StatusStory story;

  @override
  Widget build(BuildContext context) {
    if (story.isAsset) {
      return Image.asset(story.imageRef, fit: BoxFit.cover);
    }
    return Image.network(
      story.imageRef,
      fit: BoxFit.cover,
      loadingBuilder: (_, child, progress) {
        if (progress == null) return child;
        return Container(
          color: AppColors.creamDark,
          child: const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      },
      errorBuilder: (_, __, ___) => Container(
        color: AppColors.creamDark,
        child: const Icon(Icons.image_not_supported_outlined, color: AppColors.maroon),
      ),
    );
  }
}

class _AnimatedRingPainter extends CustomPainter {
  _AnimatedRingPainter({
    required this.rotation,
    required this.borderWidth,
    required this.colors,
  });

  final double rotation;
  final double borderWidth;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - borderWidth / 2;

    final rect = Rect.fromCircle(center: center, radius: radius);
    final gradient = SweepGradient(
      startAngle: rotation,
      endAngle: rotation + 2 * math.pi,
      colors: colors,
    );

    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _AnimatedRingPainter oldDelegate) {
    return oldDelegate.rotation != rotation;
  }
}
