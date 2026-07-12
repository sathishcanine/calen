import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/post.dart';
import '../models/post_block.dart';
import '../services/calendar_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/post_content_view.dart';

const _kAppFooter =
    '\n\nமுருகன் காலண்டரை இலவசமாக உங்கள் ஆண்ட்ராய்டு மொபைலில் தரவிறக்கம் செய்ய :\nhttps://play.google.com/store/apps/details?id=com.tamilarworld.tamilar_calendar\nகிளிக் செய்யவும்';

class PostDetailScreen extends StatefulWidget {
  const PostDetailScreen({
    super.key,
    required this.repository,
    required this.postId,
    this.initialPost,
  });

  final CalendarRepository repository;
  final String postId;
  final Post? initialPost;

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  Post? _post;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.initialPost != null) {
      _post = widget.initialPost;
      _loading = false;
    }
    _load();
  }

  Future<void> _load() async {
    if (widget.initialPost == null) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final post = await widget.repository.getPost(widget.postId);
      if (mounted) setState(() => _post = post);
    } catch (e) {
      if (mounted && _post == null) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String get _shareText {
    final post = _post;
    if (post == null) return '';
    final String body;
    if (post.hasBlocks) {
      body = shareTextFromBlocks(post.title, post.blocks);
    } else {
      final content = post.content.trim();
      body = content.isEmpty ? post.title : '${post.title}\n\n$content';
    }
    return '$body$_kAppFooter';
  }

  String? get _shareImageUrl {
    final post = _post;
    if (post == null) return null;
    if (post.imageUrl.isNotEmpty) return post.imageUrl;
    return null;
  }

  Future<String?> _downloadImageToTemp(String imageUrl) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode != 200) return null;
      final dir = await getTemporaryDirectory();
      final ext = imageUrl.toLowerCase().endsWith('.webp') ? 'webp' : 'jpg';
      final file = File('${dir.path}/share_post.$ext');
      await file.writeAsBytes(response.bodyBytes);
      return file.path;
    } catch (_) {
      return null;
    }
  }

  Future<void> _shareWhatsApp() async {
    final text = _shareText;
    if (text.isEmpty) return;
    final imageUrl = _shareImageUrl;
    if (imageUrl != null) {
      final imagePath = await _downloadImageToTemp(imageUrl);
      if (imagePath != null) {
        await SharePlus.instance.share(ShareParams(
          files: [XFile(imagePath)],
          text: text,
        ));
        return;
      }
    }
    final uri = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(text)}');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('WhatsApp திறக்க முடியவில்லை')),
      );
    }
  }

  Future<void> _shareGeneric() async {
    final text = _shareText;
    if (text.isEmpty) return;
    final imageUrl = _shareImageUrl;
    if (imageUrl != null) {
      final imagePath = await _downloadImageToTemp(imageUrl);
      if (imagePath != null) {
        await SharePlus.instance.share(ShareParams(
          files: [XFile(imagePath)],
          text: text,
        ));
        return;
      }
    }
    await SharePlus.instance.share(ShareParams(text: text));
  }

  Future<void> _shareFacebook() async {
    final text = _shareText;
    if (text.isEmpty) return;
    final uri = Uri.parse(
      'https://www.facebook.com/sharer/sharer.php?quote=${Uri.encodeComponent(text)}',
    );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Facebook திறக்க முடியவில்லை')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('பதிவு'),
        backgroundColor: AppColors.maroon,
        foregroundColor: Colors.white,
      ),
      body: _loading && _post == null
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _post == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton(onPressed: _load, child: const Text('மீண்டும் முயற்சி')),
                      ],
                    ),
                  ),
                )
              : _buildContent(theme),
    );
  }

  Widget _buildContent(ThemeData theme) {
    final post = _post!;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            post.title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.maroon,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 16),
          _ShareRow(
            onWhatsApp: _shareWhatsApp,
            onShare: _shareGeneric,
            onFacebook: _shareFacebook,
          ),
          const SizedBox(height: 20),
          PostContentView(
            blocks: post.blocks,
            legacyContent: post.content,
            legacyImageUrl: post.imageUrl,
            useLegacyLayout: !post.hasBlocks,
          ),
        ],
      ),
    );
  }
}

class _ShareRow extends StatelessWidget {
  const _ShareRow({
    required this.onWhatsApp,
    required this.onShare,
    required this.onFacebook,
  });

  final VoidCallback onWhatsApp;
  final VoidCallback onShare;
  final VoidCallback onFacebook;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ShareButton(
          label: 'WhatsApp',
          icon: Icons.chat_rounded,
          color: const Color(0xFF25D366),
          onTap: onWhatsApp,
        ),
        const SizedBox(width: 10),
        _ShareButton(
          label: 'பகிர்',
          icon: Icons.share_rounded,
          color: AppColors.goldDark,
          onTap: onShare,
        ),
        const SizedBox(width: 10),
        _ShareButton(
          label: 'Facebook',
          icon: Icons.facebook_rounded,
          color: const Color(0xFF1877F2),
          onTap: onFacebook,
        ),
      ],
    );
  }
}

class _ShareButton extends StatelessWidget {
  const _ShareButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color,
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
