import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class BannerAdManager {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  static const String _testAdUnitId = 'ca-app-pub-3940256099942544/6300978111';
  static String? _productionAdUnitId;

  // Inicializa UMA VEZ no app (chame no main)
  static Future<void> initialize() async {
    try {
      const channel = MethodChannel('com.rgvieira63.repertorio/ad_config');
      _productionAdUnitId = await channel.invokeMethod('getBannerAdUnitId');
    } catch (e) {
      _productionAdUnitId = _testAdUnitId;
    }
  }

  String get _adUnitId {
    // Usa o ID de teste em debug e o ID real em produção
    return kReleaseMode && _productionAdUnitId != null
        ? _productionAdUnitId!
        : _testAdUnitId;
  }

  Future<void> loadBanner() async {
    _bannerAd?.dispose();
    _isLoaded = false;

    _bannerAd = BannerAd(
      adUnitId: _adUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          _isLoaded = true;
          debugPrint('✅ BannerAd carregado: $_adUnitId');
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _isLoaded = false;
          debugPrint('❌ Falha ao carregar BannerAd ($_adUnitId): $error');
          Future.delayed(const Duration(seconds: 5), loadBanner);
        },
        onAdClosed: (ad) {
          debugPrint('BannerAd fechado');
        },
      ),
    )..load();
  }

  Widget buildBannerWidget() {
    if (_isLoaded && _bannerAd != null) {
      return SizedBox(
        width: _bannerAd!.size.width.toDouble(),
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
