class BookCategory {
  const BookCategory({
    required this.id,
    required this.name,
    required this.sortOrder,
    required this.bookCount,
  });

  final String id;
  final String name;
  final int sortOrder;
  final int bookCount;

  factory BookCategory.fromJson(Map<String, dynamic> json) {
    return BookCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      sortOrder: json['sort_order'] as int? ?? 0,
      bookCount: json['book_count'] as int? ?? 0,
    );
  }
}

class LibraryBook {
  const LibraryBook({
    required this.id,
    required this.categoryId,
    required this.title,
    required this.author,
    required this.pdfUrl,
    this.previewUrl,
    required this.fileSize,
    required this.sortOrder,
    this.createdAt,
  });

  final String id;
  final String categoryId;
  final String title;
  final String author;
  final String pdfUrl;
  final String? previewUrl;
  final int fileSize;
  final int sortOrder;
  final DateTime? createdAt;

  factory LibraryBook.fromJson(Map<String, dynamic> json) {
    DateTime? created;
    final raw = json['created_at'];
    if (raw is String && raw.isNotEmpty) {
      created = DateTime.tryParse(raw);
    }
    return LibraryBook(
      id: json['id'] as String,
      categoryId: json['category_id'] as String,
      title: json['title'] as String,
      author: json['author'] as String? ?? '',
      pdfUrl: json['pdf_url'] as String,
      previewUrl: json['preview_url'] as String?,
      fileSize: json['file_size'] as int? ?? 0,
      sortOrder: json['sort_order'] as int? ?? 0,
      createdAt: created,
    );
  }
}
