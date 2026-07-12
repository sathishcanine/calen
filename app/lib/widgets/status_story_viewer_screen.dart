import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/status_story.dart';
import '../services/status_story_service.dart';
import '../theme/app_theme.dart';
import '../utils/app_share.dart';

class StatusStoryViewerScreen extends StatefulWidget {
  const StatusStoryViewerScreen({
    super.key,
    required this.stories,
    required this.initialIndex,
    required this.viewedIds,
  });

  final List<StatusStory> stories;
  final int initialIndex;
  final Set<String> viewedIds;

  @override
  State<StatusStoryViewerScreen> createState() => _StatusStoryViewerScreenState();
}

class _StatusStoryViewerScreenState extends State<StatusStoryViewerScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static const _storyDuration = Duration(seconds: 5);

  late final PageController _pageController;
  late final AnimationController _progress;
  late int _index;
  bool _paused = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _index = widget.initialIndex;
    _pageController = PageController(initialPage: _index);
    _progress = AnimationController(vsync: this, duration: _storyDuration)
      ..addStatusListener(_onProgressStatus);
    _markCurrentViewed();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startProgress());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _progress.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _pauseProgress();
    } else if (state == AppLifecycleState.resumed && _paused) {
      _resumeProgress();
    }
  }

  void _onProgressStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _advanceToNext();
    }
  }

  void _startProgress() {
    if (!mounted) return;
    _progress
      ..stop()
      ..reset()
      ..forward();
    _paused = false;
  }

  void _pauseProgress() {
    if (_progress.isAnimating) {
      _progress.stop();
      _paused = true;
    }
  }

  void _resumeProgress() {
    if (_paused && mounted) {
      _progress.forward();
      _paused = false;
    }
  }

  Future<void> _markCurrentViewed() async {
    await StatusStoryService.instance.markViewed(widget.stories[_index].id);
  }

  void _onPageChanged(int i) {
    if (i == _index) return;
    setState(() => _index = i);
    _markCurrentViewed();
    _startProgress();
  }

  void _advanceToNext() {
    if (_index >= widget.stories.length - 1) {
      if (mounted) Navigator.pop(context);
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  void _goPrevious() {
    if (_index > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    } else {
      _startProgress();
    }
  }

  void _goNext() {
    if (_index < widget.stories.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    } else if (mounted) {
      Navigator.pop(context);
    }
  }

  void _onTapUp(TapUpDetails details, double width) {
    if (details.globalPosition.dx < width * 0.35) {
      _goPrevious();
    } else {
      _goNext();
    }
  }

  Future<void> _shareCurrent() async {
    _pauseProgress();
    final story = widget.stories[_index];
    try {
      final file = await _resolveShareFile(story);
      final body = [
        if (story.title.isNotEmpty) story.title,
        if (story.caption.isNotEmpty) story.caption,
        if (story.title.isEmpty && story.caption.isEmpty)
          'தமிழர் உலகம் — தமிழ் காலண்டர்',
      ].join('\n');
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: AppShare.withInstallFooter(body),
          subject: story.title.isNotEmpty ? story.title : 'தமிழர் உலகம்',
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('பகிர முடியவில்லை: $e')),
      );
    } finally {
      _resumeProgress();
    }
  }

  Future<File> _resolveShareFile(StatusStory story) async {
    final dir = await getTemporaryDirectory();
    final ext = _extensionFromRef(story.imageRef);
    final out = File('${dir.path}/status_${story.id}$ext');

    if (story.isAsset) {
      final data = await rootBundle.load(story.imageRef);
      await out.writeAsBytes(data.buffer.asUint8List(), flush: true);
      return out;
    }

    if (await out.exists()) return out;

    final res = await http.get(Uri.parse(story.imageRef));
    if (res.statusCode != 200) {
      throw Exception('Download failed');
    }
    await out.writeAsBytes(res.bodyBytes, flush: true);
    return out;
  }

  String _extensionFromRef(String ref) {
    final uri = Uri.tryParse(ref);
    final path = uri?.path ?? ref;
    final dot = path.lastIndexOf('.');
    if (dot == -1) return '.jpg';
    return path.substring(dot);
  }

  @override
  Widget build(BuildContext context) {
    final story = widget.stories[_index];
    final width = MediaQuery.sizeOf(context).width;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                itemCount: widget.stories.length,
                onPageChanged: _onPageChanged,
                itemBuilder: (context, i) {
                  return GestureDetector(
                    onTapUp: (details) => _onTapUp(details, width),
                    onLongPressStart: (_) => _pauseProgress(),
                    onLongPressEnd: (_) => _resumeProgress(),
                    child: Center(
                      child: _StoryImage(story: widget.stories[i]),
                    ),
                  );
                },
              ),
              Positioned(
                top: 8,
                left: 12,
                right: 12,
                child: _StoryProgressBar(
                  count: widget.stories.length,
                  currentIndex: _index,
                  progress: _progress,
                ),
              ),
              Positioned(
                top: 20,
                left: 8,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (story.title.isNotEmpty || story.caption.isNotEmpty) ...[
                      if (story.title.isNotEmpty)
                        Text(
                          story.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            shadows: [
                              Shadow(color: Colors.black54, blurRadius: 6),
                            ],
                          ),
                        ),
                      if (story.caption.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          story.caption,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.92),
                            fontSize: 14,
                            shadows: const [
                              Shadow(color: Colors.black54, blurRadius: 6),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                    ],
                    Center(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _shareCurrent,
                          borderRadius: BorderRadius.circular(28),
                          child: Ink(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFC2185B), Color(0xFFAD1457)],
                              ),
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.35),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                              border: Border.all(
                                color: AppColors.gold.withValues(alpha: 0.55),
                              ),
                            ),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 22,
                                vertical: 12,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.share_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'பகிர்',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.3,
                                    ),
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StoryProgressBar extends StatelessWidget {
  const _StoryProgressBar({
    required this.count,
    required this.currentIndex,
    required this.progress,
  });

  final int count;
  final int currentIndex;
  final Animation<double> progress;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(count, (i) {
        return Expanded(
          child: Container(
            height: 3,
            margin: EdgeInsets.only(right: i < count - 1 ? 4 : 0),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.28),
              borderRadius: BorderRadius.circular(2),
            ),
            clipBehavior: Clip.hardEdge,
            child: _segmentFill(i),
          ),
        );
      }),
    );
  }

  Widget _segmentFill(int i) {
    if (i < currentIndex) {
      return Container(color: AppColors.gold);
    }
    if (i > currentIndex) {
      return const SizedBox.shrink();
    }
    return AnimatedBuilder(
      animation: progress,
      builder: (context, _) {
        return Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: progress.value.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.gold,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StoryImage extends StatelessWidget {
  const _StoryImage({required this.story});

  final StatusStory story;

  @override
  Widget build(BuildContext context) {
    if (story.isAsset) {
      return Image.asset(story.imageRef, fit: BoxFit.contain);
    }
    return Image.network(
      story.imageRef,
      fit: BoxFit.contain,
      loadingBuilder: (_, child, progress) {
        if (progress == null) return child;
        return const Center(
          child: CircularProgressIndicator(color: AppColors.gold),
        );
      },
      errorBuilder: (_, __, ___) => const Icon(
        Icons.broken_image_outlined,
        color: Colors.white54,
        size: 64,
      ),
    );
  }
}
