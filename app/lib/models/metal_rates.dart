class MetalRateCity {
  const MetalRateCity({
    required this.id,
    required this.nameTa,
    required this.nameEn,
  });

  factory MetalRateCity.fromJson(Map<String, dynamic> json) => MetalRateCity(
        id: json['id'] as String? ?? '',
        nameTa: json['name_ta'] as String? ?? '',
        nameEn: json['name_en'] as String? ?? '',
      );

  final String id;
  final String nameTa;
  final String nameEn;
}

class MetalRateGramRow {
  const MetalRateGramRow({
    required this.grams,
    required this.today,
    required this.yesterday,
    required this.change,
  });

  factory MetalRateGramRow.fromJson(Map<String, dynamic> json) => MetalRateGramRow(
        grams: json['grams'] as int? ?? 0,
        today: (json['today'] as num?)?.toDouble() ?? 0,
        yesterday: (json['yesterday'] as num?)?.toDouble() ?? 0,
        change: (json['change'] as num?)?.toDouble() ?? 0,
      );

  final int grams;
  final double today;
  final double yesterday;
  final double change;
}

class MetalRateGold {
  const MetalRateGold({
    required this.perGramToday,
    required this.perGramYesterday,
    required this.changePerGram,
    required this.table,
  });

  factory MetalRateGold.fromJson(Map<String, dynamic> json) => MetalRateGold(
        perGramToday: (json['per_gram_today'] as num?)?.toDouble() ?? 0,
        perGramYesterday: (json['per_gram_yesterday'] as num?)?.toDouble() ?? 0,
        changePerGram: (json['change_per_gram'] as num?)?.toDouble() ?? 0,
        table: (json['table'] as List<dynamic>? ?? [])
            .map((e) => MetalRateGramRow.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  final double perGramToday;
  final double perGramYesterday;
  final double changePerGram;
  final List<MetalRateGramRow> table;
}

class MetalRateSilverHistory {
  const MetalRateSilverHistory({
    required this.date,
    required this.perGram,
    required this.perKg,
  });

  factory MetalRateSilverHistory.fromJson(Map<String, dynamic> json) =>
      MetalRateSilverHistory(
        date: json['date'] as String? ?? '',
        perGram: (json['per_gram'] as num?)?.toDouble() ?? 0,
        perKg: (json['per_kg'] as num?)?.toDouble() ?? 0,
      );

  final String date;
  final double perGram;
  final double perKg;
}

class MetalRateSilver {
  const MetalRateSilver({
    required this.perGramToday,
    required this.perKgToday,
    required this.history,
  });

  factory MetalRateSilver.fromJson(Map<String, dynamic> json) => MetalRateSilver(
        perGramToday: (json['per_gram_today'] as num?)?.toDouble() ?? 0,
        perKgToday: (json['per_kg_today'] as num?)?.toDouble() ?? 0,
        history: (json['history'] as List<dynamic>? ?? [])
            .map((e) => MetalRateSilverHistory.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  final double perGramToday;
  final double perKgToday;
  final List<MetalRateSilverHistory> history;
}

class MetalRateGoldHistory {
  const MetalRateGoldHistory({
    required this.date,
    required this.gold22k,
    required this.gold24k,
  });

  factory MetalRateGoldHistory.fromJson(Map<String, dynamic> json) => MetalRateGoldHistory(
        date: json['date'] as String? ?? '',
        gold22k: (json['gold_22k'] as num?)?.toDouble() ?? 0,
        gold24k: (json['gold_24k'] as num?)?.toDouble() ?? 0,
      );

  final String date;
  final double gold22k;
  final double gold24k;
}

class MetalRateRecentDay {
  const MetalRateRecentDay({
    required this.date,
    required this.gold22k8g,
    required this.gold24k8g,
    required this.change22k8g,
    required this.change24k8g,
  });

  factory MetalRateRecentDay.fromJson(Map<String, dynamic> json) => MetalRateRecentDay(
        date: json['date'] as String? ?? '',
        gold22k8g: (json['gold_22k_8g'] as num?)?.toDouble() ?? 0,
        gold24k8g: (json['gold_24k_8g'] as num?)?.toDouble() ?? 0,
        change22k8g: (json['change_22k_8g'] as num?)?.toDouble() ?? 0,
        change24k8g: (json['change_24k_8g'] as num?)?.toDouble() ?? 0,
      );

  final String date;
  final double gold22k8g;
  final double gold24k8g;
  final double change22k8g;
  final double change24k8g;
}

class MetalRates {
  const MetalRates({
    required this.cityId,
    required this.cityNameTa,
    required this.cityNameEn,
    required this.period,
    required this.gold22k,
    required this.gold24k,
    required this.silver,
    required this.goldHistory,
    required this.recentDaily,
    this.lastUpdated,
  });

  factory MetalRates.fromJson(Map<String, dynamic> json) => MetalRates(
        cityId: json['city_id'] as String? ?? '',
        cityNameTa: json['city_name_ta'] as String? ?? '',
        cityNameEn: json['city_name_en'] as String? ?? '',
        period: json['period'] as String? ?? '7d',
        lastUpdated: _parseUtc(json['last_updated'] as String?),
        gold22k: MetalRateGold.fromJson(json['gold_22k'] as Map<String, dynamic>),
        gold24k: MetalRateGold.fromJson(json['gold_24k'] as Map<String, dynamic>),
        silver: MetalRateSilver.fromJson(json['silver'] as Map<String, dynamic>),
        goldHistory: (json['gold_history'] as List<dynamic>? ?? [])
            .map((e) => MetalRateGoldHistory.fromJson(e as Map<String, dynamic>))
            .toList(),
        recentDaily: (json['recent_daily'] as List<dynamic>? ?? [])
            .map((e) => MetalRateRecentDay.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  final String cityId;
  final String cityNameTa;
  final String cityNameEn;
  final String period;
  final DateTime? lastUpdated;
  final MetalRateGold gold22k;
  final MetalRateGold gold24k;
  final MetalRateSilver silver;
  final List<MetalRateGoldHistory> goldHistory;
  final List<MetalRateRecentDay> recentDaily;
}

DateTime? _parseUtc(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  final normalized = raw.endsWith('Z') ? raw : '${raw}Z';
  return DateTime.tryParse(normalized)?.toUtc();
}
