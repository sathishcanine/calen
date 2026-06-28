import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../config/ad_config.dart';
import 'firebase_service.dart';

/// Initializes Google Mobile Ads (AdMob) with Unity mediation via [gma_mediation_unity].
class AdService {
  AdService._();

  static final AdService instance = AdService._();

  bool _initialized = false;
  InterstitialAd? _interstitialAd;
  bool _loadingInterstitial = false;

  bool get isInitialized => _initialized;

  Future<void> initialize() async {
    if (!AdConfig.enabled || !AdConfig.isSupported || _initialized) return;

    try {
      final status = await MobileAds.instance.initialize();
      _initialized = true;
      debugPrint('AdMob initialized. Adapters: ${status.adapterStatuses}');
      await preloadInterstitial();
    } catch (e, stack) {
      debugPrint('AdMob initialization failed: $e\n$stack');
      await FirebaseService.instance.recordError(e, stack);
    }
  }

  Future<void> preloadInterstitial() async {
    if (!_initialized || _loadingInterstitial || _interstitialAd != null) return;

    _loadingInterstitial = true;
    await InterstitialAd.load(
      adUnitId: AdConfig.interstitialUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _loadingInterstitial = false;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _interstitialAd = null;
              preloadInterstitial();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _interstitialAd = null;
              preloadInterstitial();
            },
          );
        },
        onAdFailedToLoad: (error) {
          _loadingInterstitial = false;
          debugPrint('Interstitial failed to load: $error');
        },
      ),
    );
  }

  Future<void> showInterstitialIfReady() async {
    final ad = _interstitialAd;
    if (ad == null) {
      await preloadInterstitial();
      return;
    }
    await ad.show();
    _interstitialAd = null;
  }

  void dispose() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
  }
}
