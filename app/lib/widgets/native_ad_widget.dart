import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../config/ad_config.dart';
import '../services/ad_service.dart';
import '../theme/app_theme.dart';

/// Native ad bar for detail screens (AdMob native template).
class NativeAdWidget extends StatefulWidget {
  const NativeAdWidget({
    super.key,
    this.templateType = TemplateType.small,
    this.adUnitId,
  });

  final TemplateType templateType;
  final String? adUnitId;

  @override
  State<NativeAdWidget> createState() => _NativeAdWidgetState();
}

class _NativeAdWidgetState extends State<NativeAdWidget> {
  NativeAd? _nativeAd;
  bool _isLoaded = false;

  double get _height => widget.templateType == TemplateType.small ? 92 : 320;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  Future<void> _loadAd() async {
    if (!AdConfig.enabled ||
        !AdService.instance.isInitialized ||
        _nativeAd != null) {
      return;
    }

    final nativeAd = NativeAd(
      adUnitId: widget.adUnitId ?? AdConfig.nativeUnitId,
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          if (mounted) setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          debugPrint('Native ad failed to load: $error');
        },
      ),
      request: const AdRequest(),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: widget.templateType,
        mainBackgroundColor: AppColors.surface,
        cornerRadius: 10,
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: AppColors.textPrimary,
          size: 14,
        ),
        secondaryTextStyle: NativeTemplateTextStyle(
          textColor: AppColors.textSecondary,
          size: 12,
        ),
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: AppColors.surface,
          backgroundColor: AppColors.maroon,
          size: 13,
        ),
      ),
    );

    await nativeAd.load();
    if (!mounted) {
      nativeAd.dispose();
      return;
    }

    setState(() => _nativeAd = nativeAd);
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded || _nativeAd == null) {
      return const SizedBox.shrink();
    }

    return ColoredBox(
      color: AppColors.cream,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
          child: SizedBox(
            height: _height,
            width: double.infinity,
            child: AdWidget(ad: _nativeAd!),
          ),
        ),
      ),
    );
  }
}
