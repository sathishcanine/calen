import 'dart:convert';

import 'package:flutter/services.dart';

/// Pre-exported vastu + pancha pakshi article content (no server needed).
class SpiritualStaticBundle {
  SpiritualStaticBundle._();

  static final SpiritualStaticBundle instance = SpiritualStaticBundle._();

  static const _assetPath = 'assets/data/spiritual_bundle.json';

  Map<String, dynamic>? _data;

  Future<void> load() async {
    if (_data != null) return;
    final raw = await rootBundle.loadString(_assetPath);
    _data = jsonDecode(raw) as Map<String, dynamic>;
  }

  Map<String, dynamic> get data {
    final bundle = _data;
    if (bundle == null) throw StateError('SpiritualStaticBundle not loaded');
    return bundle;
  }
}
