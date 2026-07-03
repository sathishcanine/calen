/// City metadata from GET /cities — bilingual display for pickers.
class City {
  const City({
    required this.id,
    required this.nameEn,
    required this.nameTa,
    required this.displayName,
    required this.lat,
    required this.lon,
    required this.tzOffset,
    required this.country,
    this.timezone,
    this.isDefault = false,
  });

  factory City.fromJson(Map<String, dynamic> json) {
    final nameEn = json['name_en'] as String? ?? '';
    final nameTa = json['name_ta'] as String? ?? '';
    return City(
      id: json['id'] as String? ?? '',
      nameEn: nameEn,
      nameTa: nameTa,
      displayName: json['display_name'] as String? ?? formatDisplayName(nameEn, nameTa),
      lat: (json['lat'] as num?)?.toDouble() ?? 0,
      lon: (json['lon'] as num?)?.toDouble() ?? 0,
      tzOffset: (json['tz_offset'] as num?)?.toDouble() ?? 5.5,
      country: json['country'] as String? ?? 'IN',
      timezone: json['timezone'] as String?,
      isDefault: json['is_default'] as bool? ?? false,
    );
  }

  final String id;
  final String nameEn;
  final String nameTa;

  /// e.g. Chennai - சென்னை — English first so Tamil-keyboard users can read both.
  final String displayName;
  final double lat;
  final double lon;
  final double tzOffset;
  final String country;
  final String? timezone;
  final bool isDefault;

  /// Match search query against English, Tamil, or combined label.
  bool matchesQuery(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return nameEn.toLowerCase().contains(q) ||
        nameTa.contains(query.trim()) ||
        displayName.toLowerCase().contains(q) ||
        id.replaceAll('_', ' ').contains(q);
  }
}

String formatDisplayName(String nameEn, String nameTa) {
  final en = nameEn.trim();
  final ta = nameTa.trim();
  if (ta.isNotEmpty && ta != en) {
    return '$en - $ta';
  }
  return en;
}
