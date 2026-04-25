import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:developer' as dev;

class RewardedAdService {
  RewardedAd? _rewardedAd;
  bool _isLoading = false;

  // Test ID oficial do Google (trocar depois pelo real)
  // Android Rewarded:
  // ca-app-pub-3940256099942544/5224354917
  final String adUnitId = 'ca-app-pub-3940256099942544/5224354917';

  static final RewardedAdService _instance = RewardedAdService._internal();
  factory RewardedAdService() => _instance;

  RewardedAdService._internal();

  bool get isAvailable => _rewardedAd != null;

  void load() {
    if (_isLoading || _rewardedAd != null) return;
    _isLoading = true;

    RewardedAd.load(
      adUnitId: adUnitId,
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
              // opcional: recarregar pro próximo uso
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
      load(); // tenta carregar pra próxima
      return false;
    }

    _rewardedAd!.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
      onReward(reward);
    });

    // depois de mostrar, o callback de fullScreenContentCallback cuida de dispose+reload
    return true;
  }
}
