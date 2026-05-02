import 'package:flutter/services.dart';

class AdConfig {
  static const _channel = MethodChannel('com.seuapp/ad_config');

  static Future<String> getBannerAdUnitId() async {
    try {
      final String id = await _channel.invokeMethod('getBannerAdUnitId');
      return id;
    } catch (e) {
      return 'ca-app-pub-3940256099942544/6300978111'; // fallback teste
    }
  }

  static Future<String> getRewardedAdUnitId() async {
    try {
      final String id = await _channel.invokeMethod('getRewardedAdUnitId');
      return id;
    } catch (e) {
      return 'ca-app-pub-3940256099942544/5224354917'; // fallback teste
    }
  }
}
