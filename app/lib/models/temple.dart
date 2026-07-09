class Temple {
  const Temple({
    required this.id,
    required this.slug,
    required this.nameTa,
    required this.nameEn,
    required this.locationTa,
    required this.deityTa,
    required this.descriptionTa,
    required this.imageUrl,
    required this.sourceLabel,
    required this.sourceUrl,
    required this.sortOrder,
    required this.isFeatured,
  });

  factory Temple.fromJson(Map<String, dynamic> json) => Temple(
        id: json['id'] as int,
        slug: json['slug'] as String? ?? '',
        nameTa: json['name_ta'] as String? ?? '',
        nameEn: json['name_en'] as String? ?? '',
        locationTa: json['location_ta'] as String? ?? '',
        deityTa: json['deity_ta'] as String? ?? '',
        descriptionTa: json['description_ta'] as String? ?? '',
        imageUrl: json['image_url'] as String? ?? '',
        sourceLabel: json['source_label'] as String? ?? 'Wikipedia',
        sourceUrl: json['source_url'] as String? ?? '',
        sortOrder: json['sort_order'] as int? ?? 0,
        isFeatured: json['is_featured'] as bool? ?? false,
      );

  final int id;
  final String slug;
  final String nameTa;
  final String nameEn;
  final String locationTa;
  final String deityTa;
  final String descriptionTa;
  final String imageUrl;
  final String sourceLabel;
  final String sourceUrl;
  final int sortOrder;
  final bool isFeatured;
}
