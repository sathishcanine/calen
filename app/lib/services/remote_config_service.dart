import 'dart:convert';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../models/app_update_config.dart';
import 'firebase_service.dart';

class RemoteConfigService {
  RemoteConfigService._();

  static final RemoteConfigService instance = RemoteConfigService._();

  static const _packageName = 'com.tamilarworld.tamilar_calendar';
  static const _playStoreUrl =
      'https://play.google.com/store/apps/details?id=$_packageName';

  static const _defaults = <String, dynamic>{
    'force_update_enabled': false,
    'min_supported_version_code': 1,
    'update_data':
        '{"show":"false","title":"புதிய பதிப்பு கிடைக்கிறது","whats_new":""}',
  };

  Future<AppUpdateConfig?> checkForRequiredUpdate() async {
    if (!FirebaseService.isSupported || !FirebaseService.instance.isInitialized) {
      return null;
    }

    try {
      final remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(minutes: 1),
          minimumFetchInterval:
              kDebugMode ? Duration.zero : const Duration(hours: 1),
        ),
      );
      await remoteConfig.setDefaults(_defaults);
      await remoteConfig.fetchAndActivate();

      final forceUpdateEnabled =
          remoteConfig.getBool('force_update_enabled');
      if (!forceUpdateEnabled) return null;

      final minSupportedVersionCode =
          remoteConfig.getInt('min_supported_version_code');
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersionCode = int.tryParse(packageInfo.buildNumber) ?? 0;

      if (currentVersionCode >= minSupportedVersionCode) return null;

      final updateData = _parseUpdateData(remoteConfig.getString('update_data'));
      if (!_readShowFlag(updateData)) return null;

      return AppUpdateConfig.fromRemoteData(
        updateData: updateData,
        defaultStoreUrl: _playStoreUrl,
      );
    } catch (e, stack) {
      debugPrint('Remote Config update check failed: $e\n$stack');
      await FirebaseService.instance.recordError(e, stack);
      return null;
    }
  }

  Map<String, dynamic> _parseUpdateData(String raw) {
    if (raw.trim().isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {
      debugPrint('Invalid update_data JSON: $raw');
    }
    return {};
  }

  bool _readShowFlag(Map<String, dynamic> updateData) {
    final value = updateData['show'];
    if (value == null) return true;
    if (value is bool) return value;
    final normalized = value.toString().trim().toLowerCase();
    return normalized == 'true' || normalized == '1' || normalized == 'yes';
  }
}
