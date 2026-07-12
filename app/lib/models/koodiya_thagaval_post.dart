import 'post_block.dart';

class KoodiyaThagavalPost {
  const KoodiyaThagavalPost({
    required this.id,
    required this.title,
    required this.content,
    required this.imageUrl,
    this.pushSent = false,
    this.createdAt,
    this.blocks = const [],
  });

  factory KoodiyaThagavalPost.fromJson(Map<String, dynamic> json) {
    final blocks = parsePostBlocks(json);
    return KoodiyaThagavalPost(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      imageUrl: json['image_url'] as String,
      pushSent: json['push_sent'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      blocks: blocks,
    );
  }

  final String id;
  final String title;
  final String content;
  final String imageUrl;
  final bool pushSent;
  final DateTime? createdAt;
  final List<PostBlock> blocks;

  String get preview => previewFromBlocks(blocks);
}
