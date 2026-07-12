enum PostBlockType { text, image }

class PostBlock {
  const PostBlock.text(this.value)
      : type = PostBlockType.text,
        url = '';

  const PostBlock.image(this.url)
      : type = PostBlockType.image,
        value = '';

  factory PostBlock.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String? ?? 'text';
    if (type == 'image') {
      return PostBlock.image(json['url'] as String? ?? '');
    }
    return PostBlock.text(json['value'] as String? ?? '');
  }

  final PostBlockType type;
  final String value;
  final String url;

  bool get isText => type == PostBlockType.text;
  bool get isImage => type == PostBlockType.image;
}

List<PostBlock> parsePostBlocks(Map<String, dynamic> json) {
  final raw = json['blocks'];
  if (raw is! List) return _legacyBlocks(json);
  final blocks = raw
      .whereType<Map<String, dynamic>>()
      .map(PostBlock.fromJson)
      .where((block) {
        if (block.isText) return block.value.trim().isNotEmpty;
        if (block.isImage) return block.url.trim().isNotEmpty;
        return false;
      })
      .toList();
  if (blocks.isNotEmpty) return blocks;
  return _legacyBlocks(json);
}

List<PostBlock> _legacyBlocks(Map<String, dynamic> json) {
  final content = json['content'] as String? ?? '';
  if (content.trim().isEmpty || content.trim().startsWith('[')) {
    return const [];
  }
  return [PostBlock.text(content)];
}

String previewFromBlocks(List<PostBlock> blocks, {int maxLen = 100}) {
  final text = blocks
      .where((block) => block.isText)
      .map((block) => block.value.trim())
      .where((value) => value.isNotEmpty)
      .join(' ')
      .replaceAll(RegExp(r'\s+'), ' ');
  if (text.isEmpty) return '';
  if (text.length <= maxLen) return text;
  return '${text.substring(0, maxLen - 1).trim()}…';
}

String shareTextFromBlocks(String title, List<PostBlock> blocks) {
  final body = blocks
      .where((block) => block.isText)
      .map((block) => block.value.trim())
      .where((value) => value.isNotEmpty)
      .join('\n\n');
  if (body.isEmpty) return title;
  return '$title\n\n$body';
}
