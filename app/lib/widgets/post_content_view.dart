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
    final paragraphs = content.split(RegExp(r'\n{2,}'));
    final widgets = <Widget>[];

    for (var i = 0; i < paragraphs.length; i++) {
      final paragraph = paragraphs[i].trimRight();
      if (paragraph.isEmpty) continue;
      widgets.add(
        Padding(
          padding: EdgeInsets.only(bottom: i < paragraphs.length - 1 ? 14 : 0),
          child: _buildParagraph(paragraph, theme),
        ),
      );
    }

    if (widgets.isEmpty && content.trim().isNotEmpty) {
      widgets.add(_buildParagraph(content, theme));
    }

    return widgets;
  }

  Widget _buildParagraph(String paragraph, ThemeData theme) {
    final baseStyle = theme.textTheme.bodyLarge?.copyWith(
      height: 1.6,
      color: const Color(0xFF2C2C2C),
    );
    final boldStyle = baseStyle?.copyWith(fontWeight: FontWeight.bold);

    final lines = paragraph.split('\n');
    final spans = <TextSpan>[];

    for (var j = 0; j < lines.length; j++) {
      final line = lines[j];
      if (j > 0) spans.add(const TextSpan(text: '\n'));
      final isLabel = RegExp(r'\s+:\s*$').hasMatch(line) || line.trimRight().endsWith(':');
      spans.add(TextSpan(
        text: line,
        style: isLabel ? boldStyle : null,
      ));
    }

    return RichText(
      text: TextSpan(style: baseStyle, children: spans),
    );
  }
}
