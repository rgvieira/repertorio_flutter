import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hive_flutter/hive_flutter.dart';

class BannerAdManager {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  static const String _testAdUnitId = 'ca-app-pub-3940256099942544/6300978111';
  static String? _productionAdUnitId;

  static Future<void> initialize() async {
    try {
      const channel = MethodChannel('com.rgvieira63.repertorio/ad_config');
      _productionAdUnitId = await channel.invokeMethod('getBannerAdUnitId');
    } catch (e) {
      _productionAdUnitId = _testAdUnitId;
    }
  }

  bool get _adsEnabled {
    try {
      return Hive.box('settings').get('adsHabilitados', defaultValue: true);
    } catch (_) {
      return true;
    }
  }

  String get _adUnitId {
    return kReleaseMode && _productionAdUnitId != null
        ? _productionAdUnitId!
        : _testAdUnitId;
  }

  Future<void> loadBanner(BuildContext context) async {
    if (!_adsEnabled) return;

    _bannerAd?.dispose();
    _isLoaded = false;

    final adaptiveSize = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
      MediaQuery.of(context).size.width.truncate(),
    ) ?? AdSize.banner;

    _bannerAd = BannerAd(
      adUnitId: _adUnitId,
      size: adaptiveSize,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          _isLoaded = true;
          debugPrint('✅ BannerAdaptivo carregado: $_adUnitId');
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _isLoaded = false;
          debugPrint('❌ Falha ao carregar BannerAd ($_adUnitId): $error');
          Future.delayed(const Duration(seconds: 5), () {
            if (context.mounted) loadBanner(context);
          });
        },
        onAdClosed: (ad) {
          debugPrint('BannerAd fechado');
        },
      ),
    )..load();
  }

  Widget buildBannerWidget() {
    if (!_adsEnabled) return const SizedBox(height: 50);

    if (_isLoaded && _bannerAd != null) {
      return SizedBox(
        width: double.infinity,
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      );
    }
    return const SizedBox(height: 50);
  }

  void dispose() {
    _bannerAd?.dispose();
    _isLoaded = false;
  }
}
