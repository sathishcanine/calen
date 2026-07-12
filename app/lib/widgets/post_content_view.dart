import 'package:flutter/material.dart';

import '../models/post_block.dart';
import '../theme/app_theme.dart';

class PostContentView extends StatelessWidget {
  const PostContentView({
    super.key,
    required this.blocks,
    this.legacyContent = '',
    this.legacyImageUrl = '',
    this.useLegacyLayout = false,
  });

  final List<PostBlock> blocks;
  final String legacyContent;
  final String legacyImageUrl;
  final bool useLegacyLayout;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (useLegacyLayout || blocks.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (legacyImageUrl.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(AppDecorations.cardRadius),
              child: Image.network(
                legacyImageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (_, child, progress) {
                  if (progress == null) return child;
                  return const AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Center(child: CircularProgressIndicator()),
                  );
                },
                errorBuilder: (_, _, _) => Container(
                  height: 200,
                  color: AppColors.cream,
                  alignment: Alignment.center,
                  child: const Icon(Icons.broken_image_outlined, size: 48),
                ),
              ),
            ),
            if (legacyContent.trim().isNotEmpty) const SizedBox(height: 20),
          ],
          ..._legacyParagraphs(legacyContent, theme),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < blocks.length; i++) ...[
          if (i > 0) SizedBox(height: blocks[i].isImage ? 18 : 14),
          if (blocks[i].isText)
            ..._legacyParagraphs(blocks[i].value, theme)
          else if (blocks[i].isImage)
            ClipRRect(
              borderRadius: BorderRadius.circular(AppDecorations.cardRadius),
              child: Image.network(
                blocks[i].url,
                fit: BoxFit.cover,
                loadingBuilder: (_, child, progress) {
                  if (progress == null) return child;
                  return const AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Center(child: CircularProgressIndicator()),
                  );
                },
                errorBuilder: (_, _, _) => Container(
                  height: 200,
                  color: AppColors.cream,
                  alignment: Alignment.center,
                  child: const Icon(Icons.broken_image_outlined, size: 48),
                ),
              ),
            ),
        ],
      ],
    );
  }

  List<Widget> _legacyParagraphs(String content, ThemeData theme) {
    final blocks = content.split(RegExp(r'\n{2,}'));
    final widgets = <Widget>[];

    for (var i = 0; i < blocks.length; i++) {
      final block = blocks[i].trimRight();
      if (block.isEmpty) continue;
      widgets.add(
        Padding(
          padding: EdgeInsets.only(bottom: i < blocks.length - 1 ? 14 : 0),
          child: Text(
            block,
            style: theme.textTheme.bodyLarge?.copyWith(
              height: 1.6,
              color: const Color(0xFF2C2C2C),
            ),
          ),
        ),
      );
    }

    if (widgets.isEmpty && content.trim().isNotEmpty) {
      widgets.add(
        Text(
          content,
          style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
        ),
      );
    }

    return widgets;
  }
}
