class PalangalCategory {
  const PalangalCategory({
    required this.id,
    required this.titleTa,
    required this.subtitleTa,
    required this.icon,
    required this.color,
    this.kind = 'articles',
  });

  final String id;
  final String titleTa;
  final String subtitleTa;
  final String icon;
  final String color;
  final String kind;

  bool get isCalculator => kind == 'calculator';

  factory PalangalCategory.fromJson(Map<String, dynamic> json) => PalangalCategory(
        id: json['id'] as String,
        titleTa: json['title_ta'] as String,
        subtitleTa: json['subtitle_ta'] as String,
        icon: json['icon'] as String,
        color: json['color'] as String,
        kind: json['kind'] as String? ?? 'articles',
      );
}

class PalangalArticle {
  PalangalArticle({
    required this.id,
    required this.categoryId,
    required this.titleTa,
  });

  final int id;
  final String categoryId;
  final String titleTa;

  factory PalangalArticle.fromJson(Map<String, dynamic> json) => PalangalArticle(
        id: json['id'] as int,
        categoryId: json['category_id'] as String,
        titleTa: json['title_ta'] as String,
      );
}

class PalangalArticleDetail {
  PalangalArticleDetail({
    required this.id,
    required this.categoryId,
    required this.titleTa,
    required this.bodyTa,
  });

  final int id;
  final String categoryId;
  final String titleTa;
  final String bodyTa;

  factory PalangalArticleDetail.fromJson(Map<String, dynamic> json) => PalangalArticleDetail(
        id: json['id'] as int,
        categoryId: json['category_id'] as String,
        titleTa: json['title_ta'] as String,
        bodyTa: json['body_ta'] as String,
      );
}
