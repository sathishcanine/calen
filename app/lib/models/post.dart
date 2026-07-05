class Post {
  const Post({
    required this.id,
    required this.title,
    required this.content,
    required this.imageUrl,
    this.pushSent = false,
    this.createdAt,
  });

  factory Post.fromJson(Map<String, dynamic> json) => Post(
        id: json['id'] as String,
        title: json['title'] as String? ?? '',
        content: json['content'] as String? ?? '',
        imageUrl: json['image_url'] as String,
        pushSent: json['push_sent'] as bool? ?? false,
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'] as String)
            : null,
      );

  final String id;
  final String title;
  final String content;
  final String imageUrl;
  final bool pushSent;
  final DateTime? createdAt;
}
