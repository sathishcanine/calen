class StatusStory {
  const StatusStory({
    required this.id,
    required this.imageRef,
    required this.title,
    required this.createdAt,
    this.isAsset = false,
    this.caption = '',
  });

  factory StatusStory.fromJson(Map<String, dynamic> json) {
    final imageRef = json['image_url'] as String? ??
        json['image_ref'] as String? ??
        '';
    return StatusStory(
      id: json['id'] as String? ?? '',
      imageRef: imageRef,
      title: json['title'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      isAsset: json['is_asset'] as bool? ??
          (!imageRef.startsWith('http') && imageRef.startsWith('assets/')),
      caption: json['caption'] as String? ?? '',
    );
  }

  final String id;
  /// Network URL or Flutter asset path (when [isAsset]).
  final String imageRef;
  final String title;
  final DateTime createdAt;
  final bool isAsset;
  final String caption;

  bool get isNetwork => imageRef.startsWith('http');

  Map<String, dynamic> toJson() => {
        'id': id,
        'image_ref': imageRef,
        'title': title,
        'created_at': createdAt.toIso8601String(),
        'is_asset': isAsset,
        'caption': caption,
      };

  StatusStory copyWith({
    String? title,
    String? caption,
  }) =>
      StatusStory(
        id: id,
        imageRef: imageRef,
        title: title ?? this.title,
        createdAt: createdAt,
        isAsset: isAsset,
        caption: caption ?? this.caption,
      );
}
