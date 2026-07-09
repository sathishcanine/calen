import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

/// AdMob IDs from `--dart-define`. Defaults use Google's official test IDs.
class AdConfig {
  AdConfig._();

  static const bool enabled = bool.fromEnvironment(
    'ADS_ENABLED',
    defaultValue: true,
  );

  static const String androidAppId = String.fromEnvironment(
    'ADMOB_ANDROID_APP_ID',
    defaultValue: 'ca-app-pub-4789468551786381~4569236322',
  );

  static const String iosAppId = String.fromEnvironment(
    'ADMOB_IOS_APP_ID',
    defaultValue: 'ca-app-pub-3940256099942544~1458002511',
  );

  static const String androidBannerUnitId = String.fromEnvironment(
    'ADMOB_ANDROID_BANNER_ID',
    defaultValue: 'ca-app-pub-3940256099942544/6300978111',
  );

  static const String iosBannerUnitId = String.fromEnvironment(
    'ADMOB_IOS_BANNER_ID',
    defaultValue: 'ca-app-pub-3940256099942544/2934735716',
  );

  static const String androidInterstitialUnitId = String.fromEnvironment(
    'ADMOB_ANDROID_INTERSTITIAL_ID',
    defaultValue: 'ca-app-pub-3940256099942544/1033173712',
  );

  static const String androidBudgetInterstitialUnitId = String.fromEnvironment(
    'ADMOB_ANDROID_BUDGET_INTERSTITIAL_ID',
    defaultValue: 'ca-app-pub-4789468551786381/1926533177',
  );

  static const String androidNativeUnitId = String.fromEnvironment(
    'ADMOB_ANDROID_NATIVE_ID',
    defaultValue: 'ca-app-pub-4789468551786381/4833296911',
  );

  static const String androidHomeNativeUnitId = String.fromEnvironment(
    'ADMOB_ANDROID_HOME_NATIVE_ID',
    defaultValue: 'ca-app-pub-4789468551786381/3587327145',
  );

  static const String androidMetalRatesNativeUnitId = String.fromEnvironment(
    'ADMOB_ANDROID_METAL_RATES_NATIVE_ID',
    defaultValue: 'ca-app-pub-4789468551786381/5115004531',
  );

  static const String androidBudgetNativeUnitId = String.fromEnvironment(
    'ADMOB_ANDROID_BUDGET_NATIVE_ID',
    defaultValue: 'ca-app-pub-4789468551786381/5602054301',
  );

  static const String androidTempleNativeUnitId = String.fromEnvironment(
    'ADMOB_ANDROID_TEMPLE_NATIVE_ID',
    defaultValue: 'ca-app-pub-4789468551786381/7645224713',
  );

  static const String iosNativeUnitId = String.fromEnvironment(
    'ADMOB_IOS_NATIVE_ID',
    defaultValue: 'ca-app-pub-3940256099942544/3986624511',
  );

  static const String iosHomeNativeUnitId = String.fromEnvironment(
    'ADMOB_IOS_HOME_NATIVE_ID',
    defaultValue: 'ca-app-pub-3940256099942544/3986624511',
  );

  static const String iosMetalRatesNativeUnitId = String.fromEnvironment(
    'ADMOB_IOS_METAL_RATES_NATIVE_ID',
    defaultValue: 'ca-app-pub-3940256099942544/3986624511',
  );

  static const String iosBudgetNativeUnitId = String.fromEnvironment(
    'ADMOB_IOS_BUDGET_NATIVE_ID',
    defaultValue: 'ca-app-pub-3940256099942544/3986624511',
  );

  static const String iosTempleNativeUnitId = String.fromEnvironment(
    'ADMOB_IOS_TEMPLE_NATIVE_ID',
    defaultValue: 'ca-app-pub-3940256099942544/3986624511',
  );

  static const String iosInterstitialUnitId = String.fromEnvironment(
    'ADMOB_IOS_INTERSTITIAL_ID',
    defaultValue: 'ca-app-pub-3940256099942544/4411468910',
  );

  static const String iosBudgetInterstitialUnitId = String.fromEnvironment(
    'ADMOB_IOS_BUDGET_INTERSTITIAL_ID',
    defaultValue: 'ca-app-pub-3940256099942544/4411468910',
  );

  static bool get isSupported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  static String get bannerUnitId =>
      Platform.isIOS ? iosBannerUnitId : androidBannerUnitId;

  static String get interstitialUnitId =>
      Platform.isIOS ? iosInterstitialUnitId : androidInterstitialUnitId;

  static String get budgetInterstitialUnitId => Platform.isIOS
      ? iosBudgetInterstitialUnitId
      : androidBudgetInterstitialUnitId;

  static String get nativeUnitId =>
      Platform.isIOS ? iosNativeUnitId : androidNativeUnitId;

  static String get homeNativeUnitId =>
      Platform.isIOS ? iosHomeNativeUnitId : androidHomeNativeUnitId;

  static String get metalRatesNativeUnitId => Platform.isIOS
      ? iosMetalRatesNativeUnitId
      : androidMetalRatesNativeUnitId;

  static String get budgetNativeUnitId =>
      Platform.isIOS ? iosBudgetNativeUnitId : androidBudgetNativeUnitId;

  static String get templeNativeUnitId =>
      Platform.isIOS ? iosTempleNativeUnitId : androidTempleNativeUnitId;
}
