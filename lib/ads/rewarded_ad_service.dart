import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/services.dart';
import 'dart:developer' as dev;

class RewardedAdService {
  RewardedAd? _rewardedAd;
  bool _isLoading = false;

  static const String _testAdUnitId = 'ca-app-pub-3940256099942544/5224354917';
  static String? _productionAdUnitId;

  // Singleton
  static final RewardedAdService _instance = RewardedAdService._internal();
  factory RewardedAdService() => _instance;
  RewardedAdService._internal();

  // Inicializa UMA VEZ no app (chame no main)
  static Future<void> initialize() async {
    try {
      const channel = MethodChannel('com.rgvieira63.repertorio/ad_config');
      _productionAdUnitId = await channel.invokeMethod('getRewardedAdUnitId');
    } catch (e) {
      _productionAdUnitId = _testAdUnitId;
    }
  }

  String get _adUnitId {
    const bool isProduction = bool.fromEnvironment('dart.vm.product');
    return isProduction
        ? (_productionAdUnitId ?? _testAdUnitId)
        : _testAdUnitId;
  }

  bool get isAvailable => _rewardedAd != null;

  void dispose() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
  }

  void load() {
    if (_isLoading || _rewardedAd != null) return;
    _isLoading = true;

    RewardedAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          dev.log('Rewarded loaded');
          _rewardedAd = ad;
          _isLoading = false;

          _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              dev.log('Rewarded dismissed');
              ad.dispose();
              _rewardedAd = null;
              load();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              dev.log('Failed to show: $error');
              ad.dispose();
              _rewardedAd = null;
              load();
            },
          );
        },
        onAdFailedToLoad: (LoadAdError error) {
          dev.log('Failed to load rewarded: $error');
          _isLoading = false;
          _rewardedAd = null;
        },
      ),
    );
  }

  Future<bool> show({required Function(RewardItem reward) onReward}) async {
    if (_rewardedAd == null) {
      dev.log('Rewarded not available');
      load();
      return false;
    }

    _rewardedAd!.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
      onReward(reward);
    });

    return true;
  }
}
